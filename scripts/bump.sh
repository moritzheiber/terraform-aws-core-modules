#!/bin/bash

set -Eeu -o pipefail

PREVIOUS_VERSION=${1:-}
VERSION="${2:-}"

_check_versions() {
  if [ "x${VERSION}" == "x" ] || [ "x${PREVIOUS_VERSION}" == "x" ]; then
    echo "Missing version numbers"
    echo "${0} previous_version new_version"
    exit 1
  fi
}

_bump_version() {
  local dirs

  cd ../

 #shellcheck disable=SC2035
  dirs=$(git ls-files *.tf | cut -f1 -d'/' | uniq | tr '\n' ',')

 #shellcheck disable=SC2046
  sed -i "s/${PREVIOUS_VERSION//v}/${VERSION//v}/g" docs/readme.tmpl
    terraform-module-docs --dirs "${dirs:0:${#dirs}-1}" --template docs/readme.tmpl > README.md
}

_check_versions
_bump_version
