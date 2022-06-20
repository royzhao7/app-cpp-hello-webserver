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
RUN     set -x && \
        sudo apt update && \
        sudo apt install --assume-yes \
            openssh-client \
            && \
        sudo apt clean && \
        sudo rm -rf /var/lib/apt/lists/* && \
        :

# Create conan profile and update settings
RUN     set -x && \
        conan profile \
            new \
            default \
            --detect \
            && \
        conan profile \
            update \
            settings.compiler.libcxx=libstdc++11 \
            default \
            && \
        :
