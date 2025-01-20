#!/bin/bash -e
################################################################################
##  File:  install-Helm.sh
##  Desc:  Installs helm
################################################################################

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
cp /tmp/helm/linux-amd64/helm /usr/local/bin/helm

invoke_tests "Tools" "Helm"