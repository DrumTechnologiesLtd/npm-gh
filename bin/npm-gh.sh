#!/bin/bash
# A simple npm wrapper for using GitHub as a light-weight npm registry.
#

# initial set-up
PACKAGE_DIR=$( pwd )
PACKAGE_JSON=$PACKAGE_DIR/package.json
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
SCRIPT_NAME=$( basename "${BASH_SOURCE[0]}" )
BASE_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
JSON_PARSER=$BASE_DIR/node_modules/JSON.sh/JSON.sh
TMP_DIR=~/tmp/${SCRIPT_NAME}.$$
PARSED_JSON=${TMP_DIR}/parsed_json

# echo the supplied params, and then exit with an error
function errExit {
  echo "*** Error running ${SCRIPT_NAME}"
  while [ $# -gt 0 ]
  do
    echo "** $1"
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

# pre-flight checks for the existence of npm, git, the JSON.sh parser,
# and a package.json in the current working directory
if [ -z `which npm` ]
then
  errExit
    "No 'npm' available on the command line."   \
    "Please install npm on your system and try again."
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

if [ ! -f ${PACKAGE_JSON} ]
then
  errExit                                               \
    "No package.json in ${PACKAGE_DIR}."                \
    "Are you sure you are in the right place?"
fi

# pre-flight checks complete.

# initial check for simple npm pass-through invocation.
if [ "$1" != "publish" ]
then
  callNpm $*
fi

# Extract the package name, version, and the registry co-ordinates from the package.json
mkdir -p ${TMP_DIR}
${JSON_PARSER} <${PACKAGE_JSON} >${PARSED_JSON}

name=`getJsonVal name`
version=`getJsonVal version`
registryType=`getJsonVal registry.type`
registryUrl=`getJsonVal registry.url`

# if either the registryType is not "git",
# or any of the registryUrl, version and package name are empty,
# this script can't do anything so invoke npm in case it can.
if [ "${registryType}" != "git" ] || [ -z "${registryUrl}" ] || [ -z "${name}" ] || [ -z "${version}" ]
then
  rm -rf ${TMP_DIR}
  callNpm $*
fi

# create a tarball of the package, excluding:
# filespecs in the $BASE_DIR/exclusions file
# filespecs in .gitignore (if it exists)
#
cp ${BASE_DIR}/exclusions ${TMP_DIR}/exclusions
if [ -f ${PACKAGE_DIR}/.gitignore ]
then
  cat ${PACKAGE_DIR}/.gitignore >>${TMP_DIR}/exclusions
fi

cd ${PACKAGE_DIR}
tar -cvzf                               \
  ${TMP_DIR}/${name}-${version}.tgz     \
  -X ${TMP_DIR}/exclusions              \
  .

# Extract the tarball to a (new) branch of the $registryUrl, add, commit and push it up
# Note: this will allow you to update an existing published version.
# While this is bad practice, the script allows it to keep things simple.
cd ${TMP_DIR}
mkdir registry
cd registry
git init
git checkout -b ${name}/${version}
git remote add origin ${registryUrl}

# try to pull an existing version, just in case it exists,
# but then over-write it if it does
git pull origin ${name}/${version}
git rm -rf *

tar xvf ${TMP_DIR}/${name}-${version}.tgz
git add *
git commit -m "Added ${name}-${version}. package.json dependency = \"${name}\": \"git+ssh://${registryUrl}#${name}-${version}\""
git push origin ${name}/${version}

echo Added ${name}-${version} to ${registryUrl}
echo Get it by adding the following dependency to your package.json:
echo "\"${name}\": \"git+ssh://${registryUrl}#${name}-${version}\""

# Tidy up
cd ${PACKAGE_DIR}
rm -rf ${TMP_DIR}
