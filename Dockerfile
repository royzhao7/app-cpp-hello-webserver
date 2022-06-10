ARG     BASE_BUILDER_IMAGE=debian:11
ARG     BASE_RUNTIME_IMAGE=gcr.io/distroless/cc-debian11:nonroot

FROM    ${BASE_BUILDER_IMAGE} as build

# Install the required development tools
# Use a build arg for the build-essential to allow overriding for crossbuild
ARG     BUILD_ESSENTIAL_PKG=build-essential
RUN     set -x && \
        apt update && \
        apt install --assume-yes \
            autoconf \
            ${BUILD_ESSENTIAL_PKG} \
            cmake \
            curl \
            git \
            pkg-config \
            python3-pip \
            unzip \
            wget \
            xz-utils \
            zip \
        && \
        apt clean && \
        rm -rf /var/lib/apt/lists/* && \
        :
# Configure gcc environment variables based on selected architecture
ARG     GNU_ARCH=x86_64
ENV     AR=${GNU_ARCH}-linux-gnu-ar
ENV     AS=${GNU_ARCH}-linux-gnu-as
ENV     CC=${GNU_ARCH}-linux-gnu-gcc
ENV     CMAKE_C_COMPILER=${GNU_ARCH}-linux-gnu-gcc
ENV     CMAKE_CXX_COMPILER=${GNU_ARCH}-linux-gnu-g++
ENV     CPP=${GNU_ARCH}-linux-gnu-cpp
ENV     CXX=${GNU_ARCH}-linux-gnu-g++
ENV     LD=${GNU_ARCH}-linux-gnu-ld
ENV     NM=${GNU_ARCH}-linux-gnu-nm
ENV     OBJCOPY=${GNU_ARCH}-linux-gnu-objcopy
ENV     OBJDUMP=${GNU_ARCH}-linux-gnu-objdump
ENV     RANLIB=${GNU_ARCH}-linux-gnu-ranlib
ENV     READELF=${GNU_ARCH}-linux-gnu-readelf
ENV     STRIP=${GNU_ARCH}-linux-gnu-strip
# Install conan and configure the default profile
ARG     CONAN_VERSION=1.49.0
ARG     CONAN_ARCH=${GNU_ARCH}
RUN     set -x && \
        pip install conan==${CONAN_VERSION} && \
        conan profile new \
            default \
            --detect \
            && \
        conan profile update \
            settings.compiler.libcxx=libstdc++11 \
            default \
            && \
        conan profile update \
            settings.arch=${CONAN_ARCH} \
            default \
            && \
        :

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
            --build missing \
            --install-folder app/build/ \
            && \
        :

# Build application
COPY    . \
        app/
RUN     set -x && \
        cmake \
            -S app/ \
            -B app/build/ \
            -DCMAKE_BUILD_TYPE=Release \
            && \
        cmake \
            --build app/build/ \
            -j$(($(nproc) + 1)) \
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
