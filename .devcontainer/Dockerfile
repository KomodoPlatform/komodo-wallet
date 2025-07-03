FROM docker.io/ubuntu:22.04

ENV FLUTTER_VERSION="3.32.5"
ENV USER="komodo"
ENV USER_ID=1000
ENV PATH=$PATH:/opt/flutter/bin
ENV PATH=$PATH:/android-ndk/bin
ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en
ENV TMPDIR=/tmp/ \
    ANDROID_DATA=/ \
    ANDROID_DNS_MODE=local \
    ANDROID_ROOT=/system

ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

# comes from https://developer.android.com/studio/#command-tools
ENV ANDROID_SDK_TOOLS_VERSION=11076708

# https://developer.android.com/studio/releases/build-tools
ENV ANDROID_PLATFORM_VERSION=35
ENV ANDROID_BUILD_TOOLS_VERSION=35.0.1

# https://developer.android.com/ndk/downloads
ENV ANDROID_NDK_VERSION=27.2.12479018

RUN apt update && apt install -y sudo && \
    useradd -u $USER_ID -m $USER && \ 
    usermod -aG sudo $USER && \ 
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /workspaces && \ 
    chown -R $USER:$USER /workspaces && \ 
    chown -R $USER:$USER /opt

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential 	\
    libssl-dev \ 
    cmake \
    llvm-dev \
    libclang-dev \ 
    lld \
    gcc \
    libc6-dev \
    jq \
    make \
    pkg-config \
    git \
    automake \
    libtool \
    m4 \
    autoconf \
    make \
    file \
    curl \
    wget \
    gnupg \
    software-properties-common 	\
    lsb-release \
    libudev-dev \
    zip unzip \
    nodejs npm \
    binutils && \
    apt-get clean

USER $USER

RUN set -e -o xtrace \
    && cd /opt \
    && sudo chown -R $USER:$USER /opt \
    && sudo apt-get update \
    && sudo apt-get install -y jq \
    openjdk-17-jdk \
    # For Linux build
    clang cmake git \
    ninja-build pkg-config \
    libgtk-3-dev liblzma-dev \
    libstdc++-12-dev \
    xz-utils \
    wget zip unzip git openssh-client curl bc software-properties-common build-essential \
    ruby-full ruby-bundler libstdc++6 libpulse0 libglu1-mesa locales lcov \
    libsqlite3-dev --no-install-recommends \
    # for x86 emulators
    libxtst6 libnss3-dev libnspr4 libxss1 libatk-bridge2.0-0 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' \
    && sudo locale-gen \
    && sudo update-locale LANG=en_US.UTF-8 \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip -O android-sdk-tools.zip \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools/ \
    && unzip -q android-sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools/ \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && sudo chown -R $USER:$USER $ANDROID_HOME \
    && rm android-sdk-tools.zip \
    && yes | sdkmanager --licenses \
    && sdkmanager platform-tools \
    && git config --global user.email "hello@komodoplatform.com" \
    && git config --global user.name "Komodo Platform" \
    && yes | sdkmanager \
    "platforms;android-$ANDROID_PLATFORM_VERSION" \
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"

RUN cd /opt && \
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
    tar -xvf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt && \
    rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
    flutter config --no-analytics && \
    flutter precache && \
    yes "y" | flutter doctor --android-licenses && \
    flutter doctor && \
    flutter update-packages --verify-only  && \
    mkdir -p /workspaces/komodo-wallet && \
    chown -R $USER_ID:$USER_ID /workspaces/komodo-wallet