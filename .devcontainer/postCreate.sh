#!/usr/bin/env bash

set -euo pipefail

# Initialize and pin submodules to the recorded commits
git submodule sync --recursive
git submodule update --init --recursive --checkout

# Recommended git settings for submodules
git config fetch.recurseSubmodules on-demand
git config submodule.sdk.ignore dirty

echo "postCreate: completed submodule initialization and permissions setup"
