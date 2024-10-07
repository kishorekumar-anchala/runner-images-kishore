#!/bin/bash -e
################################################################################
##  File:  install-azure-cli.sh
##  Desc:  Install Azure CLI (az)
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/etc-environment.sh



# Install Azure CLI (instructions taken from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "azure-cli https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt" >> $HELPER_SCRIPTS/apt-sources.txt

export AZURE_CONFIG_DIR="$HOME/.azure"
mkdir -p $AZURE_CONFIG_DIR
set_etc_environment_variable "AZURE_CONFIG_DIR" $AZURE_CONFIG_DIR

export AZURE_EXTENSION_DIR="$HOME/.azure/cli-extensions"
mkdir -p $AZURE_EXTENSION_DIR
set_etc_environment_variable "AZURE_EXTENSION_DIR" $AZURE_EXTENSION_DIR

echo "Warmup 'az'"
az --help > /dev/null
if [ $? -ne 0 ]; then
    echo "Command 'az --help' failed"
    exit 1
fi

rm -f /etc/apt/sources.list.d/azure-cli.list
rm -f /etc/apt/sources.list.d/azure-cli.list.save

invoke_tests "CLI.Tools" "Azure CLI"
