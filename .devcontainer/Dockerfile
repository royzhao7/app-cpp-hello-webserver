ARG     BASE_DEV_IMAGE=conanio/gcc10:1.49.0

FROM    ${BASE_DEV_IMAGE} AS dev

# Add the Continental CA Certifcate to the list of trusted certificates (required for secure http when within VPN)
ARG     INSTALL_CONTI_CA_CERT=true
RUN     set -x && \
        if [ "${INSTALL_CONTI_CA_CERT}" = "true" ]; then \
            sudo wget \
                -O /usr/local/share/ca-certificates/CorporateITSecurity.crt \
                http://ca.conti.de/ccacert.crt \
                && \
            sudo update-ca-certificates && \
            :; \
        fi && \
        :

# Install openssh-client to enable pull/push from git urls
# Install jq as it is a requirement for yq (to be installed later below)
RUN     set -x && \
        sudo apt update && \
        sudo apt install --assume-yes \
            openssh-client \
            jq \
            && \
        sudo apt clean && \
        sudo rm -rf /var/lib/apt/lists/* && \
        :

# Install yq (required to update the conan settings.yml later)
ARG     YQ_VERSION=2.14.0
RUN     set -x && \
        pip install yq==${YQ_VERSION} && \
        :

# Install the musl.cc toolchain
# Note: using gcc 10 similar to the current base builder image
ARG     MUSL_CC_TOOLCHAIN=https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-native.tgz
RUN     set -x && \
        curl \
            --output /tmp/musl-cc-toolchain.tgz \
            ${MUSL_CC_TOOLCHAIN} \
            && \
        sudo mkdir /usr/local/muslcc && \
        sudo tar \
            --extract \
            --file /tmp/musl-cc-toolchain.tgz \
            --directory /usr/local/muslcc \
            --strip-components 1 \
            && \
        rm /tmp/musl-cc-toolchain.tgz && \
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
        conan profile \
            update \
            settings.compiler.libcxx=libstdc++11 \
            default \
            && \
        :

# Create a muslcc conan profile and update its settings
RUN     set -x && \
        conan profile \
            new \
            muslcc \
            --detect \
            && \
        conan profile \
            update \
            settings.compiler.libcxx=libstdc++11 \
            muslcc \
            && \
        conan profile \
            update \
            settings.compiler.libc=musl \
            muslcc \
            && \
        conan profile \
            update \
            env.AR=/usr/local/muslcc/bin/ar \
            muslcc \
            && \
        conan profile \
            update \
            env.AS=/usr/local/muslcc/bin/as \
            muslcc \
            && \
        conan profile \
            update \
            env.CC=/usr/local/muslcc/bin/gcc \
            muslcc \
            && \
        conan profile \
            update \
            env.CPP=/usr/local/muslcc/bin/cpp \
            muslcc \
            && \
        conan profile \
            update \
            env.CXX=/usr/local/muslcc/bin/g++ \
            muslcc \
            && \
        conan profile \
            update \
            env.LD=/usr/local/muslcc/bin/ld \
            muslcc \
            && \
        conan profile \
            update \
            env.NM=/usr/local/muslcc/bin/nm \
            muslcc \
            && \
        conan profile \
            update \
            env.OBJCOPY=/usr/local/muslcc/bin/objcopy \
            muslcc \
            && \
        conan profile \
            update \
            env.OBJDUMP=/usr/local/muslcc/bin/objdump \
            muslcc \
            && \
        conan profile \
            update \
            env.RANLIB=/usr/local/muslcc/bin/ranlib \
            muslcc \
            && \
        conan profile \
            update \
            env.READELF=/usr/local/muslcc/bin/readelf \
            muslcc \
            && \
        conan profile \
            update \
            env.STRIP=/usr/local/muslcc/bin/strip \
            muslcc \
            && \
        conan profile \
            update \
            conf.tools.build:exelinkflags='[ "-static-libgcc", "-static-libstdc++", "-static" ]' \
            muslcc \
            && \
        conan profile \
            update \
            conf.tools.build:sysroot=/usr/local/muslcc/ \
            muslcc \
            && \
        :
