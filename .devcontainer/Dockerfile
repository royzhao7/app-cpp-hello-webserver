# This development environment supports native and cross builds using gcc
ARG     BASE_DEV_IMAGE=debian:11

FROM    ${BASE_DEV_IMAGE} AS dev

# Install the required development tools
RUN     set -x && \
        apt update && \
        apt install --assume-yes \
            automake \
            cmake \
            curl \
            # will bring in openssh-client via recommends
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
ARG     CONAN_VERSION=1.51.1
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
# Install additional tools used in the development container
#   - sudo to allow non-root user privileged operations
RUN     set -x && \
        apt update && \
        apt install --assume-yes \
            sudo \
            && \
        apt clean && \
        rm -rf /var/lib/apt/lists/* && \
        :
# Create a non-root user for this development container, and give sudo rights
ARG     USERNAME=vscode
ARG     GROUPNAME=${USERNAME}
ARG     USER_UID=1000
ARG     USER_GID=1000
RUN     set -x && \
        groupadd \
            --gid ${USER_GID} \
            ${GROUPNAME} \
            && \
        useradd \
            --uid ${USER_UID} \
            --gid ${USER_GID} \
            --create-home \
            ${USERNAME} \
            && \
        echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
        chmod 0440 /etc/sudoers.d/${USERNAME} && \
        :
# Switch to the non-root user
USER    ${USERNAME}
# Enable all aliases already defined in .bashrc
RUN     set -x && \
        sed --in-place \
            's/#alias/alias/g' \
            $HOME/.bashrc \
            && \
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
