# This Dockerfile supports, via build arguments, the following build variants:
# - native build using gcc and muslcc
# - cross build using gcc and muslcc

ARG     BASE_BUILDER_IMAGE=debian:11
ARG     BASE_RUNTIME_IMAGE=gcr.io/distroless/cc-debian11:nonroot

FROM    ${BASE_BUILDER_IMAGE} as builder

# Install the required development tools
# Use a build arg to allow specifying g++ for cross builds, e.g. setting to g++-aarch64-linux-gnu
ARG     CROSS_COMPILER_PKG=""
RUN     set -x && \
        apt update && \
        apt install --assume-yes \
            automake \
            cmake \
            ${CROSS_COMPILER_PKG} \
            curl \
            git \
            # required by yq
            jq \
            pkg-config \
            # will bring in build-essential via recommends
            python3-pip \
            unzip \
            wget \
            zip \
        && \
        apt clean && \
        rm -rf /var/lib/apt/lists/* && \
        :
# Add the Continental CA Certifcate to the list of trusted certificates (required for secure http when within VPN)
ARG     INSTALL_CONTI_CA_CERT=true
RUN     set -x && \
        if [ "${INSTALL_CONTI_CA_CERT}" = "true" ]; then \
            wget \
                -O /usr/local/share/ca-certificates/CorporateITSecurity.crt \
                http://ca.conti.de/ccacert.crt \
                && \
            update-ca-certificates && \
            :; \
        fi && \
        :
# Install the musl.cc toolchain
# Note: using gcc 10 similar to the current base builder image
ARG     MUSL_CC_TOOLCHAIN=https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-native.tgz
RUN     set -x && \
        curl \
            --output /tmp/musl-cc-toolchain.tgz \
            ${MUSL_CC_TOOLCHAIN} \
            && \
        mkdir /usr/local/muslcc && \
        tar \
            --extract \
            --file /tmp/musl-cc-toolchain.tgz \
            --directory /usr/local/muslcc \
            --strip-components 1 \
            && \
        rm /tmp/musl-cc-toolchain.tgz && \
        :
# Install conan and yq (required to update the conan settings.yml later)
ARG     CONAN_VERSION=1.49.0
ARG     YQ_VERSION=2.14.0
RUN     set -x && \
        pip install \
            conan==${CONAN_VERSION} \
            yq==${YQ_VERSION} \
            && \
        :
# Initialize and update conan settings to differentiate between glibc and musl
RUN     set -x && \
        conan config init && \
        yq \
            --in-place \
            --yml-roundtrip \
            '.compiler.gcc += { "libc": [ "None", "glibc", "musl" ] }' \
            $HOME/.conan/settings.yml \
            && \
        :
# Update conan default profile's settings
RUN     set -x && \
        conan profile update \
            settings.compiler.libcxx=libstdc++11 \
            default \
            && \
        :
# Create a gcc conan profile and update its settings
ARG     GNU_HOST_ARCH=x86_64
ARG     CONAN_HOST_ARCH=x86_64
RUN     set -x && \
        conan profile new \
            gcc \
            --detect \
            && \
        conan profile update \
            settings.arch=${CONAN_HOST_ARCH} \
            gcc \
            && \
        conan profile update \
            settings.compiler.libcxx=libstdc++11 \
            gcc \
            && \
        conan profile update \
            env.AR=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ar \
            gcc \
            && \
        conan profile update \
            env.AS=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-as \
            gcc \
            && \
        conan profile update \
            env.CC=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-gcc \
            gcc \
            && \
        conan profile update \
            env.CPP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-cpp \
            gcc \
            && \
        conan profile update \
            env.CXX=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-g++ \
            gcc \
            && \
        conan profile update \
            env.LD=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ld \
            gcc \
            && \
        conan profile update \
            env.NM=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-nm \
            gcc \
            && \
        conan profile update \
            env.OBJCOPY=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-objcopy \
            gcc \
            && \
        conan profile update \
            env.OBJDUMP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-objdump \
            gcc \
            && \
        conan profile update \
            env.RANLIB=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ranlib \
            gcc \
            && \
        conan profile update \
            env.READELF=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-readelf \
            gcc \
            && \
        conan profile update \
            env.STRIP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-strip \
            gcc \
            && \
        :
# Create a muslcc conan profile and update its settings
RUN     set -x && \
        conan profile new \
            muslcc \
            --detect \
            && \
        conan profile update \
            settings.arch=${CONAN_HOST_ARCH} \
            muslcc \
            && \
        conan profile update \
            settings.compiler.libcxx=libstdc++11 \
            muslcc \
            && \
        conan profile update \
            settings.compiler.libc=musl \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/ar ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-ar \
                /usr/local/muslcc/bin/ar \
            ; \
        fi && \
        conan profile update \
            env.AR=/usr/local/muslcc/bin/ar \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/as ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-as \
                /usr/local/muslcc/bin/as \
            ; \
        fi && \
        conan profile update \
            env.AS=/usr/local/muslcc/bin/as \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/gcc ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-gcc \
                /usr/local/muslcc/bin/gcc \
            ; \
        fi && \
        conan profile update \
            env.CC=/usr/local/muslcc/bin/gcc \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/cpp ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-cpp \
                /usr/local/muslcc/bin/cpp \
            ; \
        fi && \
        conan profile update \
            env.CPP=/usr/local/muslcc/bin/cpp \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/g++ ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-g++ \
                /usr/local/muslcc/bin/g++ \
            ; \
        fi && \
        conan profile update \
            env.CXX=/usr/local/muslcc/bin/g++ \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/ld ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-ld \
                /usr/local/muslcc/bin/ld \
            ; \
        fi && \
        conan profile update \
            env.LD=/usr/local/muslcc/bin/ld \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/nm ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-nm \
                /usr/local/muslcc/bin/nm \
            ; \
        fi && \
        conan profile update \
            env.NM=/usr/local/muslcc/bin/nm \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/objcopy ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-objcopy \
                /usr/local/muslcc/bin/objcopy \
            ; \
        fi && \
        conan profile update \
            env.OBJCOPY=/usr/local/muslcc/bin/objcopy \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/objdump ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-objdump \
                /usr/local/muslcc/bin/objdump \
            ; \
        fi && \
        conan profile update \
            env.OBJDUMP=/usr/local/muslcc/bin/objdump \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/ranlib ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-ranlib \
                /usr/local/muslcc/bin/ranlib \
            ; \
        fi && \
        conan profile update \
            env.RANLIB=/usr/local/muslcc/bin/ranlib \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/readelf ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-readelf \
                /usr/local/muslcc/bin/readelf \
            ; \
        fi && \
        conan profile update \
            env.READELF=/usr/local/muslcc/bin/readelf \
            muslcc \
            && \
        if [ ! -f /usr/local/muslcc/bin/strip ]; then \
            ln \
                --symbolic \
                --relative \
                /usr/local/muslcc/bin/${GNU_HOST_ARCH}-linux-musl-strip \
                /usr/local/muslcc/bin/strip \
            ; \
        fi && \
        conan profile update \
            env.STRIP=/usr/local/muslcc/bin/strip \
            muslcc \
            && \
        # In order to take advantage of musl's ability to produce pure static executables
        # Note: will allow using scratch and distroless/static as base runtime images
        conan profile update \
            conf.tools.build:exelinkflags='[ "-static-libgcc", "-static-libstdc++", "-static" ]' \
            muslcc \
            && \
        conan profile update \
            conf.tools.build:sysroot=/usr/local/muslcc/ \
            muslcc \
            && \
        :

FROM    builder AS build

# Define the build and host conan profiles to use
ARG     CONAN_BUILD_PROFILE=default
ARG     CONAN_HOST_PROFILE=gcc
# Install the application dependencies
COPY    remotes.txt \
        /tmp/remotes.txt
RUN     set -x && \
        conan config \
            install \
            /tmp/remotes.txt
COPY    conanfile.py \
        app/
RUN     set -x && \
        conan install \
            app/ \
            --profile:build ${CONAN_BUILD_PROFILE} \
            --profile:host ${CONAN_HOST_PROFILE} \
            --build missing \
            --install-folder app/build/ \
            && \
        :

# Build application
COPY    . \
        app/
RUN     set -x && \
        conan build \
            app/ \
            --build-folder app/build/ \
            && \
        :

# An optional label to ease removable of this intermediate image, can be set by user via build arg
ARG     AUTO_DELETE_LABEL=intermediate_image
LABEL   autodeletelabel="${AUTO_DELETE_LABEL}"

FROM    ${BASE_RUNTIME_IMAGE} as run

# Define the non-root user of the runtime image as args to allow generalizing the below instructions
ARG     RUNTIME_USER=nonroot
ARG     RUNTIME_GROUP=nonroot

# Update the PATH env var to include the non-root home
ENV     PATH="/home/${RUNTIME_USER}:${PATH}"

# Copy built application to working directory
COPY    --from=build \
            --chown=${RUNTIME_USER}:${RUNTIME_GROUP} \
            app/build/bin/ \
            /home/${RUNTIME_USER}/

# Document the used application port
EXPOSE  5000

# Set the default command to run the application
CMD     [ "app" ]
