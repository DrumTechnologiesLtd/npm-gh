#!/bin/bash
# A simple npm wrapper for using GitHub as a light-weight npm registry.
#

# echo the supplied params, and then return
function errNoExit {
  echo "** Error running ${SCRIPT_NAME}"
  while [ $# -gt 0 ]
  do
    echo "*** $1"
    shift
  done
}

# echo the supplied params, and then exit with an error
function errExit {
  echo "** Error running ${SCRIPT_NAME}"
  while [ $# -gt 0 ]
  do
    echo "*** $1"
    shift
  done
  exit 1
}

# common way of invoking npm
function callNpm {
  echo
  echo "${SCRIPT_NAME}: "
  echo "  calling: npm $*"
  npm $*
  exit $?
}

# extract a JSON value from JSON which has been pre-parsed with JSON.sh
function getJsonVal {
  prop=\\[\"${1//\./\",\"}\"\\]
  grep ${prop} <${PARSED_JSON} | ( read -r key value ; value=${value#\"} ; value=${value%\"}; echo $value)
}

# find the fully deferenced location of a file
function dereferencedFilePath {
  pushd . > /dev/null
  _source="$1"
  _dir="$( dirname "$_source" )"
  while [ -h "$_source" ]
  do
    _source="$(readlink "$_source")"
    [[ $_source != /* ]] && _source="$_dir/$_source"
    _dir="$( cd -P "$( dirname "$_source"  )" && pwd )"
  done
  _dir="$( cd -P "$( dirname "$_source" )" && pwd )"
  popd  > /dev/null
  echo "$_dir"
}

# initialise bits and pieces
SCRIPT_DIR=`dereferencedFilePath "${BASH_SOURCE[0]}"`
SCRIPT_NAME=`basename "${BASH_SOURCE[0]}"`
BASE_DIR=`cd "${SCRIPT_DIR}/.." >/dev/null && pwd`
JSON_PARSER=$BASE_DIR/node_modules/JSON.sh/JSON.sh

# pre-flight checks for the existence of npm, git, the JSON.sh parser,

if [ -z `which npm` ]
then
  errExit
    "No 'npm' available on the command line."           \
    "Please install npm on your system and try again."
fi

# initial check for simple npm pass-through invocation.
if [ "$1" != "publish" ]
then
  callNpm $*
else
  shift
fi

if [ -z `which git` ]
then
  errExit                                               \
    "No 'git' available on the command line."           \
    "Please install git on your system and try again."
fi

if [ ! -f ${JSON_PARSER} ] || [ ! -x ${JSON_PARSER} ]
then
  errExit                                               \
    "JSON.sh not found, or is not executable"           \
    "Have you run 'npm install' in ${BASE_DIR} ?"
fi


# pre-flight checks complete.

if [ $# -le 0 ]
then
  set "`pwd`"
fi

while [ $# -gt 0 ]
do
  echo
  echo "* Processing $1"

  if [ -d "$1" ]
  then
    pushd "$1" >/dev/null
    PACKAGE_DIR=`pwd -L`
    PACKAGE_NAME=`basename "${PACKAGE_DIR}"`
    PACKAGE_JSON=$PACKAGE_DIR/package.json
    TMP_DIR=~/tmp/${SCRIPT_NAME}.${PACKAGE_NAME}.$$
    PARSED_JSON=${TMP_DIR}/parsed_json

    echo "* Checking for ${PACKAGE_JSON}"

    if [ ! -f "${PACKAGE_JSON}" ]
    then
      errNoExit                                             \
        "No package.json in ${PACKAGE_DIR}."                \
        "Are you sure you are in the right place?"
    else
      # Extract the package name, version, and the registry co-ordinates from the package.json
      echo "* Creating ${TMP_DIR}"
      mkdir -p "${TMP_DIR}"
      "${JSON_PARSER}" <"${PACKAGE_JSON}" >"${PARSED_JSON}"

      name=`getJsonVal name`
      version=`getJsonVal version`
      registryType=`getJsonVal registry.type`
      registryUrl=`getJsonVal registry.url`

      # if either the registryType is not "git",
      # or any of the registryUrl, version and package name are empty,
      # this script can't do anything
      if [ "${registryType}" != "git" ] || [ -z "${registryUrl}" ] || [ -z "${name}" ] || [ -z "${version}" ]
      then
        rm -rf "${TMP_DIR}"
        errNoExit                                                       \
          "Not an npm-gh appropriate package.json in ${PACKAGE_DIR}."   \
          "Are you sure you are in the right place?"
      else
        # create a tarball of the package, excluding:
        # filespecs in the $BASE_DIR/exclusions file
        # filespecs in .gitignore (if it exists)
        #
        echo "* creating tarball of ${PACKAGE_NAME} from ${PACKAGE_DIR}"

        cp "${BASE_DIR}/exclusions" "${TMP_DIR}/exclusions"
        if [ -f "${PACKAGE_DIR}/.gitignore" ]
        then
          cat "${PACKAGE_DIR}/.gitignore" >>"${TMP_DIR}/exclusions"
        fi

        cd "${PACKAGE_DIR}"
        tar -czf                                  \
          "${TMP_DIR}/${name}-${version}.tgz"     \
          -X "${TMP_DIR}/exclusions"              \
          .

        # Extract the tarball to a (new) branch of the $registryUrl, add, commit and push it up
        # Note: this will allow you to update an existing published version.
        # While this is bad practice, the script allows it to keep things simple.
        cd "${TMP_DIR}"
        mkdir registry
        cd registry
        git init -q
        git checkout -qb "${name}/${version}"
        git remote add origin "${registryUrl}"

        # try to pull an existing version, just in case it exists,
        # but then over-write it if it does
        git pull -q origin "${name}/${version}"
        git rm -rfq *

        tar xf "${TMP_DIR}/${name}-${version}.tgz"
        git add .
        git commit -qm "New ${name}/${version}."
        git push -q origin ${name}/${version}

        echo "*"
        echo "* Added ${name}/${version} to ${registryUrl}"
        echo "* Get it by adding the following dependency to your package.json:"
        echo "* \"${name}\": \"git+ssh://${registryUrl}#${name}/${version}\""
        echo

      fi
      # Tidy up
      rm -rf ${TMP_DIR}
    fi
    popd >/dev/null
  else
    errNoExit                                                 \
      "$1 is not a directory."                                \
      "Skipping..."
  fi
  shift
done
