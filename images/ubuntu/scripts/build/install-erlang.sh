#!/bin/bash -e
################################################################################
##  File:  install-erlang.sh
##  Desc:  Install erlang and rebar3
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/os.sh

source_list=/etc/apt/sources.list.d/eslerlang.list
source_key=/usr/share/keyrings/eslerlang.gpg

# If Ubuntu 20.04, download Erlang manually
if is_ubuntu20; then

  ERLANG_PACKAGE="erlang_25.3-1~focal_amd64.deb"  # Change this based on version
  ERLANG_URL="https://packages.erlang-solutions.com/ubuntu/pool/esl-erlang/$ERLANG_PACKAGE"

  # Download the package
  wget -q $ERLANG_URL -O /tmp/$ERLANG_PACKAGE

  # Install the package manually
  dpkg -i /tmp/$ERLANG_PACKAGE
  apt-get install -f -y

  echo "Erlang installed successfully on Ubuntu 20.04"
else
  # If not Ubuntu 20.04, use the package manager as usual
  # Default Repository URL for Erlang Solutions
  REPO_URL="https://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib"

  # Install Erlang
  wget -q -O - https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | gpg --dearmor > $source_key
  echo "deb [signed-by=$source_key] $REPO_URL" > $source_list
  apt-get update
  apt-get install --no-install-recommends esl-erlang
fi

# Install rebar3
rebar3_url=$(resolve_github_release_asset_url "erlang/rebar3" "endswith(\"rebar3\")" "latest")
binary_path=$(download_with_retry "$rebar3_url")
install "$binary_path" /usr/local/bin/rebar3

# Clean up source list
rm $source_list
rm $source_key

invoke_tests "Tools" "erlang"
