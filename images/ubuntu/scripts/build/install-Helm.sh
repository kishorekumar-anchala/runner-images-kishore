#!/bin/bash -e
################################################################################
##  File:  install-Helm.sh
##  Desc:  Installs helm
################################################################################

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

invoke_tests "Tools" "Helm"