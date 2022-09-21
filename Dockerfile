# This Dockerfile supports, via build arguments, native and cross builds using gcc
ARG     BASE_BUILDER_IMAGE=debian:11
ARG     BASE_RUNTIME_IMAGE=gcr.io/distroless/cc-debian11:nonroot

FROM    ${BASE_BUILDER_IMAGE} as builder

# Install the required development tools
RUN     set -x && \
        apt update && \
        apt install --assume-yes \
            automake \
            cmake \
            curl \
            git \
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
# Install toolchain for cross compling (if requested)
ARG     INSTALL_CROSS_COMPILER=true
ARG     CROSS_COMPILER_PKG=g++-aarch64-linux-gnu
RUN     set -x && \
        if [ "${INSTALL_CROSS_COMPILER}" = "true" ]; then \
            apt update && \
            apt install --assume-yes \
                ${CROSS_COMPILER_PKG} \
                && \
            apt clean && \
            rm -rf /var/lib/apt/lists/* && \
            :; \
        fi && \
        :
# Install conan
ARG     CONAN_VERSION=1.52.0
RUN     set -x && \
        pip install conan==${CONAN_VERSION} && \
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
# Create conan default config, update settings and profile
RUN     set -x && \
        conan config init && \
        if [ "${INSTALL_CONTI_CA_CERT}" = "true" ]; then \
            cat \
                /usr/local/share/ca-certificates/CorporateITSecurity.crt \
                >> $HOME/.conan/cacert.pem \
            ; \
        fi && \
        conan config set \
            general.revisions_enabled=1 \
            && \
        conan profile \
            update \
            settings.compiler.libcxx=libstdc++11 \
            default \
            && \
        :
# Create a gcc-cross conan profile and update its settings (if cross compiler is installed)
ARG     GNU_HOST_ARCH=aarch64
ARG     CONAN_HOST_ARCH=armv8
RUN     set -x && \
        if [ "${INSTALL_CROSS_COMPILER}" = "true" ]; then \
            conan profile new \
                gcc-cross \
                --detect \
                && \
            conan profile update \
                settings.arch=${CONAN_HOST_ARCH} \
                gcc-cross \
                && \
            conan profile update \
                settings.compiler.libcxx=libstdc++11 \
                gcc-cross \
                && \
            conan profile update \
                env.AR=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ar \
                gcc-cross \
                && \
            conan profile update \
                env.AS=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-as \
                gcc-cross \
                && \
            conan profile update \
                env.CC=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-gcc \
                gcc-cross \
                && \
            conan profile update \
                env.CPP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-cpp \
                gcc-cross \
                && \
            conan profile update \
                env.CXX=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-g++ \
                gcc-cross \
                && \
            conan profile update \
                env.LD=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ld \
                gcc-cross \
                && \
            conan profile update \
                env.NM=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-nm \
                gcc-cross \
                && \
            conan profile update \
                env.OBJCOPY=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-objcopy \
                gcc-cross \
                && \
            conan profile update \
                env.OBJDUMP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-objdump \
                gcc-cross \
                && \
            conan profile update \
                env.RANLIB=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-ranlib \
                gcc-cross \
                && \
            conan profile update \
                env.READELF=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-readelf \
                gcc-cross \
                && \
            conan profile update \
                env.STRIP=/usr/bin/${GNU_HOST_ARCH}-linux-gnu-strip \
                gcc-cross \
                && \
            :; \
        fi && \
        :

FROM    builder AS build

# Define the build and host conan profiles to use
ARG     CONAN_BUILD_PROFILE=default
ARG     CONAN_HOST_PROFILE=default
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
# Build and package (stripped) the application
COPY    . \
        app/
RUN     set -x && \
        conan build \
            app/ \
            --build-folder app/build/ \
            && \
        cmake \
            --build app/build/ \
            --target install/strip \
            && \
        :
# An optional label to ease removable of this intermediate image, can be set by user via build arg
ARG     AUTO_DELETE_LABEL=intermediate_image
LABEL   autodeletelabel="${AUTO_DELETE_LABEL}"

FROM    ${BASE_RUNTIME_IMAGE} as run

# Define the non-root user of the runtime image as args to allow generalizing the below instructions
ARG     RUNTIME_USER=nonroot
ARG     RUNTIME_GROUP=nonroot
# Copy built application to working directory
COPY    --from=build \
            --chown=${RUNTIME_USER}:${RUNTIME_GROUP} \
            app/build/package/ \
            /usr/
# Set the working directory
WORKDIR /usr/bin/
# Document the used application port
EXPOSE  5000
# Set the default command to run the application
CMD     [ "app" ]
