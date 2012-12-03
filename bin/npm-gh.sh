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

# extract a JSON value from the json file
function getJsonVal {
  node ${JSON_PARSER} -f "$1" -k "$2"
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

function echoComment {
  echo "${4}"
  echo "${4}Get it by adding the following dependency to your package.json:"
  echo "${4}"
  echo "${4}\"$2\": \"git+ssh://$1#$2/$3\""
  echo "${4}"
}

# initialise bits and pieces
SCRIPT_DIR=`dereferencedFilePath "${BASH_SOURCE[0]}"`
SCRIPT_NAME=`basename "${BASH_SOURCE[0]}"`
MODULE_DIR=`cd "${SCRIPT_DIR}/.." >/dev/null && pwd`
JSON_PARSER=$MODULE_DIR/lib/getValueFromJson.js

# pre-flight checks for the existence of npm, git and node

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

if [ -z `which node` ]
then
  errExit                                               \
    "No 'node' available on the command line."           \
    "Please install node on your system and try again."
fi

# pre-flight checks complete.

# if no package directories have been specified, use the current working directory
if [ $# -le 0 ]
then
  set "`pwd`"
fi

# iterate through all the package directories
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

    echo "* Checking for existence of ${PACKAGE_JSON}"

    if [ ! -f "${PACKAGE_JSON}" ]
    then
      errNoExit                                             \
        "No package.json in ${PACKAGE_DIR}."                \
        "Are you sure you are in the right place?"
    else
      # Extract the package name, version, and the registry co-ordinates from the package.json
      name=`getJsonVal "${PACKAGE_JSON}" "name"`
      version=`getJsonVal "${PACKAGE_JSON}" "version"`
      registryType=`getJsonVal "${PACKAGE_JSON}" "registry/type"`
      registryUrl=`getJsonVal "${PACKAGE_JSON}" "registry/url"`
      tarball="${TMP_DIR}/${name}-${version}.tgz"

      # if either the registryType is not "git",
      # or any of the registryUrl, version and package name are empty,
      # this script can't do anything
      if [ "${registryType}" != "git" ] || [ -z "${registryUrl}" ] || [ -z "${name}" ] || [ -z "${version}" ]
      then
        errNoExit                                                       \
          "Not an npm-gh appropriate package.json in ${PACKAGE_DIR}."   \
          "Are you sure you are in the right place?"
      else
        # create a tarball of the package, excluding:
        # filespecs in the $MODULE_DIR/exclusions file
        # filespecs in .gitignore (if it exists)
        #
        echo "* creating tarball of '${PACKAGE_NAME}' from '${PACKAGE_DIR}' in '${TMP_DIR}'"

        mkdir -p "${TMP_DIR}"
        cp "${MODULE_DIR}/exclusions" "${TMP_DIR}/exclusions"
        if [ -f "${PACKAGE_DIR}/.gitignore" ]
        then
          cat "${PACKAGE_DIR}/.gitignore" >>"${TMP_DIR}/exclusions"
        fi

        cd "${PACKAGE_DIR}"
        tar -czf                      \
          "${tarball}"                \
          -X "${TMP_DIR}/exclusions"  \
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

        tar xf "${tarball}"
        git add .
        (echo "${name}/${version}"; echoComment "${registryUrl}" "${name}" "${version}")  | git commit -qF -
        git push -fq origin ${name}/${version}:${name}/${version}

        echo "*"
        echo "* Added ${name}/${version} to ${registryUrl}"
        echoComment "${registryUrl}" "${name}" "${version}" "* "
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
