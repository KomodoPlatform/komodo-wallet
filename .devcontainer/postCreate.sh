#!/usr/bin/env bash

set -euo pipefail

# Ensure proper ownership of the workspace (best effort)
sudo chown -R komodo:komodo /workspaces/komodo-wallet || true

# Initialize and pin submodules to the recorded commits
git submodule sync --recursive || true
git submodule update --init --recursive --checkout || true

# Recommended git settings for submodules
git config fetch.recurseSubmodules on-demand || true
git config submodule.sdk.ignore dirty || true

echo "postCreate: completed submodule initialization and permissions setup"


