#!/bin/bash
# Usage: post_create_script.sh
# Description: This script is triggered from the postCreateCommand entry in .devcontainer.json and performs
#              development container image customizations
# Note: as per VS Code's documentation, the current working directory of this script is the workspace directory
#       See: https://containers.dev/implementors/json_reference/#lifecycle-scripts

# Retreive Conti CA cert and add to store
sudo wget \
    -O /usr/local/share/ca-certificates/CorporateITSecurity.crt \
    http://ca.conti.de/ccacert.crt
sudo update-ca-certificates

# install openssh-client to enable pull/push from git urls
sudo apt update
sudo apt install --assume-yes \
    openssh-client \

# Create conan profile and update settings
conan profile new default --detect
conan profile update settings.compiler.libcxx=libstdc++11 default
conan config install remotes.txt

