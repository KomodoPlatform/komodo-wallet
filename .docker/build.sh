#!/bin/bash

DEFAULT_BUILD_TARGET="web"
DEFAULT_BUILD_MODE="release"

if [ "$#" -eq 0 ]; then
    BUILD_TARGET=$DEFAULT_BUILD_TARGET
    BUILD_MODE=$DEFAULT_BUILD_MODE
elif [ "$#" -eq 2 ]; then
    BUILD_TARGET=$1
    BUILD_MODE=$2
else
    echo "Usage: $0 [<build_target> <build_mode>]\nE.g. $0 web release"
    exit 1
fi

echo "Building with target: $BUILD_TARGET, mode: $BUILD_MODE"

if [ "$(uname)" = "Darwin" ]; then
    PLATFORM_FLAG="--platform linux/amd64"
else
    PLATFORM_FLAG=""
fi

HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Use fallback UID/GID if running as root to avoid conflicts
# in GitHub Actions where the UID/GID may be 0.
# android-sdk.dockerfile attempts to create a user with the 
# provided UID/GID, so 0 is not a valid choice (already exists).
if [ "$HOST_UID" = "0" ]; then
    HOST_UID=1000
    HOST_GID=1000
fi

docker build $PLATFORM_FLAG --build-arg BUILD_USER_ID=$HOST_UID -f .docker/android-sdk.dockerfile . -t komodo/android-sdk:35
docker build $PLATFORM_FLAG -f .docker/komodo-wallet-android.dockerfile . -t komodo/komodo-wallet

# Create the build directory ourselves to prevent it from being created by the Docker daemon (as root)
mkdir -p ./build

COMMIT_HASH=$(git rev-parse --short HEAD | cut -c1-7)

ENV_ARGS=""
ENV_VARS="GITHUB_API_PUBLIC_READONLY_TOKEN TRELLO_API_KEY \
TRELLO_TOKEN TRELLO_BOARD_ID TRELLO_LIST_ID \
FEEDBACK_API_KEY FEEDBACK_PRODUCTION_URL FEEDBACK_TEST_URL \
COMMIT_HASH"

for VAR in $ENV_VARS; do
  case "$VAR" in
    GITHUB_API_PUBLIC_READONLY_TOKEN) VALUE=$GITHUB_API_PUBLIC_READONLY_TOKEN ;;
    TRELLO_API_KEY) VALUE=$TRELLO_API_KEY ;;
    TRELLO_TOKEN) VALUE=$TRELLO_TOKEN ;;
    TRELLO_BOARD_ID) VALUE=$TRELLO_BOARD_ID ;;
    TRELLO_LIST_ID) VALUE=$TRELLO_LIST_ID ;;
    FEEDBACK_API_KEY) VALUE=$FEEDBACK_API_KEY ;;
    FEEDBACK_PRODUCTION_URL) VALUE=$FEEDBACK_PRODUCTION_URL ;;
    FEEDBACK_TEST_URL) VALUE=$FEEDBACK_TEST_URL ;;
    COMMIT_HASH) VALUE=$COMMIT_HASH ;;
    *) VALUE= ;;
  esac

  [ -n "$VALUE" ] && ENV_ARGS="$ENV_ARGS -e $VAR=$VALUE"
done

# Use the provided arguments for flutter build
# Build a second time if needed, as asset downloads will require a rebuild on the first attempt
docker run $PLATFORM_FLAG --rm -v ./build:/app/build \
  -v $(pwd):/app \
  -u "$HOST_UID:$HOST_GID" \
  $ENV_ARGS \
  komodo/komodo-wallet:latest sh -c \
  "sudo chown -R komodo:komodo /app/build; flutter pub get --enforce-lockfile; flutter build web --no-pub || true; flutter build $BUILD_TARGET --config-only; flutter build $BUILD_TARGET --no-pub --dart-define=COMMIT_HASH=$COMMIT_HASH --$BUILD_MODE"
