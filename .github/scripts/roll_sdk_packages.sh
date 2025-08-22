#!/usr/bin/env bash

# Script to roll SDK packages in all Flutter/Dart projects
# Designed to handle git-based dependencies and work with the GitHub CI workflow
#
# Usage:
#   UPGRADE_ALL_PACKAGES=false TARGET_BRANCH=dev .github/scripts/roll_sdk_packages.sh
#
# Parameters:
#   UPGRADE_ALL_PACKAGES: Set to "true" to upgrade all packages, "false" to only upgrade SDK packages
#   TARGET_BRANCH: The target branch for PR creation
#
# For more details, see `docs/SDK_DEPENDENCY_MANAGEMENT.md`

# Exit on error, but with proper cleanup
set -e

# Error handling and cleanup function
cleanup() {
  local exit_code=$?
  
  # Only perform cleanup if there was an error
  if [ $exit_code -ne 0 ] && [ $exit_code -ne 100 ]; then
    echo "ERROR: Script failed with exit code $exit_code"
    # Clean up any temporary files
    find "$REPO_ROOT" -name "*.bak" -type f -delete
  fi
  
  exit $exit_code
}

# Set up trap to catch errors
trap cleanup EXIT

# Log function for better reporting
log_info() {
  echo "INFO: $1"
}

log_warning() {
  echo "WARNING: $1" >&2
}

log_error() {
  echo "ERROR: $1" >&2
}

# Validate Flutter is available
if ! command -v flutter &> /dev/null; then
  log_error "Flutter command not found. Please ensure Flutter is installed and in your PATH."
  exit 1
fi

# Configuration
# Set to "true" to upgrade all packages, "false" to only upgrade SDK packages
UPGRADE_ALL_PACKAGES=${UPGRADE_ALL_PACKAGES:-false}
# Branch to target for PR creation
TARGET_BRANCH=${TARGET_BRANCH:-"dev"}

# Get the current date for branch naming and commit messages
CURRENT_DATE=$(date '+%Y-%m-%d')
REPO_ROOT=$(pwd)
CHANGES_FILE="$REPO_ROOT/SDK_CHANGELOG.md"

# List of external SDK packages to be updated (from KomodoPlatform/komodo-defi-sdk-flutter.git)
# Local packages like 'komodo_ui_kit' and 'komodo_persistence_layer' are not included
# as they're part of this repository, not the external SDK

# SDK packages to check
SDK_PACKAGES=(
  "komodo_cex_market_data"
  "komodo_coin_updates"
  "komodo_coins"
  "komodo_defi_framework"
  "komodo_defi_local_auth"
  "komodo_defi_remote"
  "komodo_defi_rpc_methods"
  "komodo_defi_sdk"
  "komodo_defi_types"
  "komodo_defi_workers"
  "komodo_symbol_converter"
  "komodo_ui"
  "komodo_wallet_build_transformer"
  "komodo_wallet_cli"
)

# Extract version information from the pubspec.lock file
get_package_info_from_lock() {
  local package_name=$1
  local lock_file=$2
  
  # If pubspec.lock doesn't exist, return empty
  if [ ! -f "$lock_file" ]; then
    echo ""
    return
  fi
  
  # Extract the entire package section
  local start_line=$(grep -n "^  $package_name:" "$lock_file" | cut -d: -f1)
  if [ -z "$start_line" ]; then
    echo ""
    return
  fi
  
  # Find the end line (next non-indented line or EOF)
  local end_line=$(tail -n +$((start_line+1)) "$lock_file" | grep -n "^[^ ]" | head -1 | cut -d: -f1)
  if [ -z "$end_line" ]; then
    # If no end found, use end of file
    end_line=$(wc -l < "$lock_file")
  else
    # Adjust for the offset from tail command
    end_line=$((start_line + end_line))
  fi
  
  # Extract the entire section
  local package_section=$(sed -n "${start_line},${end_line}p" "$lock_file" | sed '$d')
  
  if [ -n "$package_section" ]; then
    # Get package info
    local version=$(echo "$package_section" | grep "    version:" | head -1 | sed 's/.*version: *"\([^"]*\)".*/\1/')
    local source=$(echo "$package_section" | grep "    source:" | head -1 | sed 's/.*source: *\([^ ]*\).*/\1/')
    
    # Extract git specific info if available
    local git_url=""
    local git_ref=""
    
    if echo "$package_section" | grep -q "      url:"; then
      git_url=$(echo "$package_section" | grep "      url:" | head -1 | sed 's/.*url: *"\([^"]*\)".*/\1/')
    fi
    
    if echo "$package_section" | grep -q "      resolved-ref:"; then
      git_ref=$(echo "$package_section" | grep "      resolved-ref:" | head -1 | sed 's/.*resolved-ref: *"\([^"]*\)".*/\1/')
    elif echo "$package_section" | grep -q "      ref:"; then
      git_ref=$(echo "$package_section" | grep "      ref:" | head -1 | sed 's/.*ref: *\([^ ]*\).*/\1/')
    fi
    
    # Format the output based on what we found
    if [ -n "$git_url" ] && [ -n "$git_ref" ]; then
      echo "version: \"$version\", source: $source, git: $git_url, ref: $git_ref"
    else
      echo "version: \"$version\", source: $source"
    fi
  else
    echo ""
  fi
}

# Determine dependency type for a given package in a pubspec.yaml
# Returns one of: git|path|hosted|unknown
get_dependency_type_from_pubspec() {
  local package_name=$1
  local pubspec_file=$2

  if ! grep -q "^[[:space:]]*$package_name:" "$pubspec_file"; then
    echo "unknown"
    return
  fi

  # Capture the package declaration line and the following 10 lines
  local section=$(awk -v pkg="$package_name" '
    $0 ~ "^[[:space:]]*"pkg":" { print; c=10; next }
    c>0 { print; c--; }
  ' "$pubspec_file")

  if echo "$section" | grep -q "^[[:space:]]*git:"; then
    echo "git"
    return
  fi

  if echo "$section" | grep -q "^[[:space:]]*path:"; then
    echo "path"
    return
  fi

  # Default to hosted if not git or path
  echo "hosted"
}

# Initialize changes file
echo "# SDK Package Rolls" > "$CHANGES_FILE"
echo "" >> "$CHANGES_FILE"
echo "**Date:** $CURRENT_DATE" >> "$CHANGES_FILE"
echo "**Target Branch:** $TARGET_BRANCH" >> "$CHANGES_FILE"
echo "**Upgrade Mode:** $([ "$UPGRADE_ALL_PACKAGES" = "true" ] && echo "All Packages" || echo "SDK Packages Only")" >> "$CHANGES_FILE"
echo "" >> "$CHANGES_FILE"
echo "The following SDK packages were rolled to newer versions:" >> "$CHANGES_FILE"
echo "" >> "$CHANGES_FILE"

# Find all pubspec.yaml files
echo "Finding all pubspec.yaml files..."
PUBSPEC_FILES=$(find "$REPO_ROOT" -name "pubspec.yaml" -not -path "*/build/*" -not -path "*/\.*/*" -not -path "*/ios/*" -not -path "*/android/*")

echo "Found $(echo "$PUBSPEC_FILES" | wc -l) pubspec.yaml files"

ROLLS_MADE=false

for PUBSPEC in $PUBSPEC_FILES; do
  PROJECT_DIR=$(dirname "$PUBSPEC")
  PROJECT_NAME=$(basename "$PROJECT_DIR")
  
  # Special handling for the root project
  if [ "$PROJECT_DIR" = "$REPO_ROOT" ]; then
    PROJECT_NAME="Root Project (komodo-wallet)"
    echo "Processing ROOT PROJECT ($PROJECT_DIR)"
  else
    echo "Processing $PROJECT_NAME ($PROJECT_DIR)"
  fi
  
  # Debug: Print information about processing the project
  echo "Debug info for $PROJECT_NAME:"
  echo "  - Project path: $PROJECT_DIR"
  echo "  - Full pubspec path: $PUBSPEC"
  
  cd "$PROJECT_DIR"
  
  # Check if any SDK package is listed as a dependency
  CONTAINS_SDK_PACKAGE=false
  SDK_PACKAGES_FOUND=()
  SDK_HOSTED_PACKAGES=()
  SDK_GIT_PACKAGES=()
  
  for PACKAGE in "${SDK_PACKAGES[@]}"; do
    # More robust pattern matching that allows for comments and other formatting
    if grep -q "^[[:space:]]*$PACKAGE:" "$PUBSPEC"; then
      CONTAINS_SDK_PACKAGE=true
      SDK_PACKAGES_FOUND+=("$PACKAGE")
      DEP_TYPE=$(get_dependency_type_from_pubspec "$PACKAGE" "$PUBSPEC")
      case "$DEP_TYPE" in
        git)
          echo "Found SDK package $PACKAGE (git-based) in $PROJECT_NAME"
          SDK_GIT_PACKAGES+=("$PACKAGE")
          ;;
        hosted)
          echo "Found SDK package $PACKAGE (hosted on pub.dev) in $PROJECT_NAME"
          SDK_HOSTED_PACKAGES+=("$PACKAGE")
          ;;
        path)
          echo "Found SDK package $PACKAGE (local path) in $PROJECT_NAME - skipping version bump"
          ;;
        *)
          echo "Found SDK package $PACKAGE (unknown type) in $PROJECT_NAME"
          ;;
      esac
    fi
  done
  
  if [ "$CONTAINS_SDK_PACKAGE" = true ]; then
    echo "SDK packages found in $PROJECT_NAME: ${SDK_PACKAGES_FOUND[*]}"
    
    # Save hash of current pubspec.lock
    if [ -f "pubspec.lock" ]; then
      PRE_UPDATE_HASH=$(sha256sum pubspec.lock | awk '{print $1}')
    else
      PRE_UPDATE_HASH=""
    fi
    
    # Backup current pubspec.lock
    if [ -f "pubspec.lock" ]; then
      cp pubspec.lock pubspec.lock.bak
    fi
    
    # Get the current git refs/versions for SDK packages before update
    SDK_PACKAGE_REFS_BEFORE=()
    for PACKAGE in "${SDK_PACKAGES_FOUND[@]}"; do
      if grep -q "^[[:space:]]*$PACKAGE:" "$PUBSPEC"; then
        # Get the git reference line or version line
        if grep -q -A 10 "$PACKAGE:" "$PUBSPEC" | grep -q "git:"; then
          REF_LINE=$(grep -A 10 "$PACKAGE:" "$PUBSPEC" | grep -m 1 "ref:")
          GIT_URL=$(grep -A 10 "$PACKAGE:" "$PUBSPEC" | grep -m 1 "git:")
          if [ -n "$REF_LINE" ] && [ -n "$GIT_URL" ]; then
            REF_VALUE=$(echo "$REF_LINE" | sed 's/.*ref: *\([^ ]*\).*/\1/')
            GIT_VALUE=$(echo "$GIT_URL" | sed 's/.*git: *\([^ ]*\).*/\1/')
            SDK_PACKAGE_REFS_BEFORE+=("$PACKAGE: git: $GIT_VALUE ref: $REF_VALUE")
          fi
        else
          # If not git-based, get version
          VERSION_LINE=$(grep -A 1 "$PACKAGE:" "$PUBSPEC" | tail -1)
          if [ -n "$VERSION_LINE" ]; then
            VERSION=$(echo "$VERSION_LINE" | sed 's/.*: *\([^ ]*\).*/\1/')
            SDK_PACKAGE_REFS_BEFORE+=("$PACKAGE: version: $VERSION")
          fi
        fi
      fi
    done
    
    # Perform the update - based on configuration
    if [ "$UPGRADE_ALL_PACKAGES" = "true" ]; then
      log_info "Running flutter pub upgrade --major-versions in $PROJECT_NAME (all packages)"
      if ! flutter pub upgrade --major-versions; then
        log_error "Failed to upgrade all packages in $PROJECT_NAME"
        cd "$REPO_ROOT"
        continue
      fi
    else
      log_info "Running flutter pub upgrade for SDK packages only in $PROJECT_NAME"
      # First, bump hosted SDK package constraints to latest using flutter pub add
      if [ ${#SDK_HOSTED_PACKAGES[@]} -gt 0 ]; then
        for HPKG in "${SDK_HOSTED_PACKAGES[@]}"; do
          log_info "Updating hosted SDK dependency constraint for $HPKG to latest via flutter pub add"
          if ! flutter pub add "$HPKG"; then
            log_warning "Failed to update hosted package $HPKG in $PROJECT_NAME"
            PACKAGE_UPDATE_FAILED=true
          fi
        done
      fi

      # Then, upgrade git-based SDK packages to refresh their lock entries
      if [ ${#SDK_GIT_PACKAGES[@]} -gt 0 ]; then
        log_info "Upgrading git-based SDK packages: ${SDK_GIT_PACKAGES[*]}"
        if ! flutter pub upgrade --unlock-transitive ${SDK_GIT_PACKAGES[@]}; then
          log_warning "Failed to upgrade git-based packages in $PROJECT_NAME"
          PACKAGE_UPDATE_FAILED=true
        fi
      fi

      if [ ${#SDK_HOSTED_PACKAGES[@]} -eq 0 ] && [ ${#SDK_GIT_PACKAGES[@]} -eq 0 ]; then
        log_info "No SDK packages found to upgrade in $PROJECT_NAME"
      fi
    fi
    
    # Check if the pubspec.lock was modified
    if [ -f "pubspec.lock" ]; then
      POST_UPDATE_HASH=$(sha256sum pubspec.lock | awk '{print $1}')
      
      if [ "$PRE_UPDATE_HASH" != "$POST_UPDATE_HASH" ]; then
        echo "Changes detected in $PROJECT_NAME pubspec.lock"
        ROLLS_MADE=true
        
        # Get information about packages from lock file before and after
        if [ -f "pubspec.lock.bak" ]; then
          LOCK_BEFORE="pubspec.lock.bak"
        else
          LOCK_BEFORE=""
        fi
        LOCK_AFTER="pubspec.lock"
        
        # Add the project to the changes list
        echo "## $PROJECT_NAME" >> "$CHANGES_FILE"
        echo "" >> "$CHANGES_FILE"
        
        # List the SDK packages that were rolled with detailed info
        for PACKAGE in "${SDK_PACKAGES_FOUND[@]}"; do
          echo "- Rolled \`$PACKAGE\`" >> "$CHANGES_FILE"
          
          # Get before and after info
          if [ -n "$LOCK_BEFORE" ]; then
            BEFORE_INFO=$(get_package_info_from_lock "$PACKAGE" "$LOCK_BEFORE")
          else
            BEFORE_INFO=""
          fi
          AFTER_INFO=$(get_package_info_from_lock "$PACKAGE" "$LOCK_AFTER")
          
          # Add detailed information if available
          if [ -n "$BEFORE_INFO" ] && [ -n "$AFTER_INFO" ] && [ "$BEFORE_INFO" != "$AFTER_INFO" ]; then
            echo "  - From: \`$BEFORE_INFO\`" >> "$CHANGES_FILE"
            echo "  - To: \`$AFTER_INFO\`" >> "$CHANGES_FILE"
          elif [ -n "$AFTER_INFO" ]; then
            echo "  - Current: \`$AFTER_INFO\`" >> "$CHANGES_FILE"
          fi
        done
        
        echo "" >> "$CHANGES_FILE"
      else
        echo "No changes in $PROJECT_NAME pubspec.lock"
      fi
    else
      echo "No pubspec.lock file generated for $PROJECT_NAME"
    fi
  else
    echo "No SDK packages found in $PROJECT_NAME, skipping..."
  fi
  
  cd "$REPO_ROOT"
done

# Add the SDK rolls image at the bottom of the changes file
if [ "$ROLLS_MADE" = true ]; then
  echo "![SDK Package Rolls](https://raw.githubusercontent.com/KomodoPlatform/komodo-wallet/aaf19e4605c62854ba176bf1ea75d75b3cb48df9/docs/assets/sdk-rolls.png)" >> "$CHANGES_FILE"
  echo "" >> "$CHANGES_FILE"
  
  # Clean up all .bak files to avoid committing them
  echo "Cleaning up backup files..."
  find "$REPO_ROOT" -name "*.bak" -type f -delete
fi

# Set output for GitHub Actions
if [ -n "${GITHUB_OUTPUT}" ]; then
  if [ "$ROLLS_MADE" = true ]; then
    echo "updates_found=true" >> $GITHUB_OUTPUT
    log_info "Rolls found and applied!"
    exit 0
  else
    echo "updates_found=false" >> $GITHUB_OUTPUT
    log_info "No rolls needed."
    # Exit with special code 100 to indicate no changes needed (not a failure)
    exit 100
  fi
else
  # When running outside of GitHub Actions
  if [ "$ROLLS_MADE" = true ]; then
    log_info "Rolls found and applied! See $CHANGES_FILE for details."
    exit 0
  else
    log_info "No rolls needed."
    # Exit with special code 100 to indicate no changes needed (not a failure)
    exit 100
  fi
fi
