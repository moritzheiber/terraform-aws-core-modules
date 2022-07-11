#!/bin/bash

set -Eeu -o pipefail

for module in ../config ../iam-users ../iam-resources ../vpc ../ ; do
    (
        cd "${module}"
        terraform-docs .
    )
done
