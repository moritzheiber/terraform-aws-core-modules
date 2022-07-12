#!/bin/bash

set -Eeu -o pipefail

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}") 
cd "${SCRIPT_DIR}"

for module in ../config ../iam-users ../iam-resources ../vpc ../ ; do
    (
        cd "${module}"
        terraform-docs .
    )
done
