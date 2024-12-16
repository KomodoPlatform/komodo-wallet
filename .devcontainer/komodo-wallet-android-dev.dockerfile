FROM docker.io/ubuntu:22.04

ARG KDF_BRANCH=main
ENV KDF_DIR=/kdf
ENV FLUTTER_VERSION="3.27.1"
ENV FLUTTER_HOME="/home/komodo/.flutter-sdk"
ENV USER="komodo"
ENV USER_ID=1000
ENV PATH=$PATH:$FLUTTER_HOME/bin
ENV AR=/usr/bin/llvm-ar-16
ENV CC=/usr/bin/clang-16
ENV PATH="$HOME/.cargo/bin:$PATH"
ENV PATH=$PATH:/android-ndk/bin
ENV ANDROID_HOME=/opt/android-sdk-linux \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Libz is distributed in the android ndk, but for some unknown reason it is not
# found in the build process of some crates, so we explicit set the DEP_Z_ROOT
ENV CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER=x86_64-linux-android-clang \
    CARGO_TARGET_X86_64_LINUX_ANDROID_RUNNER="qemu-x86_64 -cpu qemu64,+mmx,+sse,+sse2,+sse3,+ssse3,+sse4.1,+sse4.2,+popcnt" \
    CC_x86_64_linux_android=x86_64-linux-android-clang \
    CXX_x86_64_linux_android=x86_64-linux-android-clang++ \
    CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER=armv7a-linux-androideabi21-clang \
    CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_RUNNER=qemu-arm \
    CC_armv7_linux_androideabi=armv7a-linux-androideabi21-clang \
    CXX_armv7_linux_androideabi=armv7a-linux-androideabi21-clang++ \
    CC_aarch64_linux_android=aarch64-linux-android21-clang \
    CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=aarch64-linux-android21-clang \
    CC_armv7_linux_androideabi=armv7a-linux-androideabi21-clang \
    CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER=armv7a-linux-androideabi21-clang \
    DEP_Z_INCLUDE=/android-ndk/sysroot/usr/include/ \
    OPENSSL_STATIC=1 \
    OPENSSL_DIR=/openssl \
    OPENSSL_INCLUDE_DIR=/openssl/include \
    OPENSSL_LIB_DIR=/openssl/lib \
    RUST_TEST_THREADS=1 \
    HOME=/home/komodo/ \
    TMPDIR=/tmp/ \
    ANDROID_DATA=/ \
    ANDROID_DNS_MODE=local \
    ANDROID_ROOT=/system

ENV ANDROID_SDK_ROOT=$ANDROID_HOME \
    PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

# comes from https://developer.android.com/studio/#command-tools
ENV ANDROID_SDK_TOOLS_VERSION=11076708

# https://developer.android.com/studio/releases/build-tools
ENV ANDROID_PLATFORM_VERSION=34
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0

# https://developer.android.com/ndk/downloads
ENV ANDROID_NDK_VERSION=26.3.11579264

RUN apt update && apt install -y sudo && \
    useradd -u $USER_ID -m $USER && \ 
    usermod -aG sudo $USER && \ 
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER $USER

RUN sudo apt-get update -y && \
    sudo apt-get install -y --no-install-recommends \
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
    sudo apt-get clean

RUN sudo ln -s /usr/bin/python3 /bin/python &&\
    sudo curl --output llvm.sh https://apt.llvm.org/llvm.sh && \
    sudo chmod +x llvm.sh && \
    sudo ./llvm.sh 16 && \
    sudo rm ./llvm.sh && \
    sudo ln -s /usr/bin/clang-16 /usr/bin/clang && \
    PROTOC_ZIP=protoc-25.3-linux-x86_64.zip && \
    sudo curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v25.3/$PROTOC_ZIP && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*' && \
    sudo rm -f $PROTOC_ZIP && \
    sudo mkdir $KDF_DIR && \
    sudo chown -R $USER:$USER $KDF_DIR

RUN PATH="$HOME/.cargo/bin:$PATH" && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    export PATH="$HOME/.cargo/bin:$PATH" && \ 
    sudo chown -R $USER:$USER $HOME/.cargo && \
    rustup toolchain install nightly-2023-06-01 --no-self-update --profile=minimal && \
    rustup default nightly-2023-06-01 && \
    rustup target add aarch64-linux-android && \
    rustup target add armv7-linux-androideabi && \
    rustup target add wasm32-unknown-unknown && \
    sudo apt install -y python3 python3-pip git curl nodejs python3-venv sudo && \
    git clone https://github.com/KomodoPlatform/komodo-defi-framework.git $KDF_DIR && \
    cd $KDF_DIR && \
    git fetch --all && \
    git checkout origin/$KDF_BRANCH && \
    if [ "$(uname -m)" = "x86_64" ]; then \
    bash ./scripts/ci/android-ndk.sh x86 23; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
    bash ./scripts/ci/android-ndk.sh arm64 23; \
    else \
    echo "Unsupported architecture: $(uname -m)"; \
    exit 1; \
    fi

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

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME}  \
    && cd ${FLUTTER_HOME}  \
    && git fetch \
    && git checkout tags/$FLUTTER_VERSION \
    && flutter config --no-analytics  \
    && flutter precache \
    && yes "y" | flutter doctor --android-licenses \
    && flutter doctor \
    && flutter update-packages 