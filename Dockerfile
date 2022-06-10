ARG     BASE_BUILDER_IMAGE=conanio/gcc9:1.45.0
ARG     BASE_RUNTIME_IMAGE=gcr.io/distroless/cc-debian11:nonroot

FROM    ${BASE_BUILDER_IMAGE} as build

# The conan profile to use
ARG     CONAN_PROFILE=default

# Create the profile (if not created) and update the C++ setting
RUN     set -x && \
        if [ ! -f $HOME/.conan/profiles/${CONAN_PROFILE} ]; then \
            conan profile new \
                ${CONAN_PROFILE} \
                --detect \
                && \
            :; \
        fi && \
        conan profile update \
            settings.compiler.libcxx=libstdc++11 \
            ${CONAN_PROFILE} \
            && \
        :

# Install dependencies
COPY    --chown=conan:1001 \
            remotes.txt \
            /tmp/remotes.txt
RUN     set -x && \
        conan config \
            install \
            /tmp/remotes.txt
COPY    --chown=conan:1001 \
            conanfile.py \
            app/
RUN     set -x && \
        conan install \
            app/ \
            --profile ${CONAN_PROFILE} \
            --build missing \
            --install-folder app/build/ \
            && \
        :

# Build application
COPY    --chown=conan:1001 \
            . \
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
            /home/conan/app/build/bin/ \
            /home/${RUNTIME_USER}/

# Document the used application port
EXPOSE  5000

# Set the default command to run the application
CMD     [ "app" ]
