#!/usr/bin/env bash
set -euo pipefail

# This script validates that the SDK's build_config.json references KDF GitHub Releases
# and that those URLs resolve successfully.

CONFIG_PATH="build/web/assets/packages/komodo_defi_framework/app_build/build_config.json"

echo "Validating KDF build_config.json at: $CONFIG_PATH"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "Error: build_config.json not found at $CONFIG_PATH"
  exit 1
fi

# Ensure JSON is valid
if ! jq . "$CONFIG_PATH" > /dev/null; then
  echo "Error: build_config.json is not valid JSON"
  exit 1
fi

# Extract all URL-like string values
URLS=$(jq -r '.. | scalars | select(type=="string") | select(test("^https?://"))' "$CONFIG_PATH" | sort -u)

if [ -z "$URLS" ]; then
  echo "Error: No URLs found in build_config.json"
  exit 1
fi

# Identify KDF-related URLs (allow both framework and sdk repos to be safe)
KDF_URLS=$(echo "$URLS" | grep -Ei 'github\.com/KomodoPlatform/(komodo-defi-framework|komodo-defi-sdk-flutter)') || true

if [ -z "$KDF_URLS" ]; then
  echo "Error: No KomodoPlatform KDF-related GitHub URLs found in build_config.json"
  echo "Found URLs:"
  echo "$URLS"
  exit 1
fi

echo "Found KDF-related URLs:"
echo "$KDF_URLS"

# Ensure all KDF URLs are GitHub Releases download links
NON_RELEASE_URLS=$(echo "$KDF_URLS" | grep -Ev 'github\.com/.*/releases/download/' || true)
if [ -n "$NON_RELEASE_URLS" ]; then
  echo "Error: The following KDF URLs do not point to GitHub Releases download paths:"
  echo "$NON_RELEASE_URLS"
  exit 1
fi

# Validate that each KDF release URL resolves (HTTP 200 after redirects)
FAIL_COUNT=0
while IFS= read -r url; do
  [ -z "$url" ] && continue
  echo "Checking URL: $url"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    STATUS_CODE=$(curl -sSLI -H "Authorization: Bearer ${GITHUB_TOKEN}" "$url" -o /dev/null -w "%{http_code}")
  else
    STATUS_CODE=$(curl -sSLI "$url" -o /dev/null -w "%{http_code}")
  fi
  if [ "$STATUS_CODE" != "200" ]; then
    echo "Error: URL did not resolve with HTTP 200 (got $STATUS_CODE): $url"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
done <<< "$KDF_URLS"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "Validation failed: $FAIL_COUNT URL(s) did not resolve"
  exit 1
fi

echo "Success: All KDF GitHub Releases URLs are valid and resolvable."

