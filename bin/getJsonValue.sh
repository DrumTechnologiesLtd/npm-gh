#!/bin/bash
# A simple wrapper to a node script to extract a value from JSON, given a key.
#

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

SCRIPT_DIR=`dereferencedFilePath "${BASH_SOURCE[0]}"`
MODULE_DIR=`cd "${SCRIPT_DIR}/.." >/dev/null && pwd`
JSON_PARSER=$MODULE_DIR/lib/getValueFromJson.js
node ${JSON_PARSER} -f "$1" -k "$2"

