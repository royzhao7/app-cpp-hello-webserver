# C++ Hello Web Server
A simple C++ Web Server using cpp-httplib  

## Overview
The purpose of this repo is to demonstrate the usage of C++ in the development of containerized services in a manner similar to other programming languages.  
This involves mainly:
- the usage of [Conan](https://conan.io/) as a package manager to handle application dependencies in a generalized approach
- the usage of a [distroless](https://github.com/GoogleContainerTools/distroless) base runtime image that is suitable for any C++ application
- a development workflow based on [VS Code](https://code.visualstudio.com/)'s [Remote Development](https://code.visualstudio.com/docs/remote/remote-overview) approach

## Building and Unit Testing the Application
As mentioned above, this repo uses a remote development container environment that contains all the tools and extensions necessary to build and test the application.  
Once the development environment is loaded in VS Code, building and testing the application can be done via the GUI or the terminal window.  

### Using the GUI
The status bar will contain all actions of the used/loaded extensions, e.g.,
- Selecting a Conan profile, e.g., for the application or the unit test or both
- Installing dependencies based on the chosen Conan profile
- Building the application/unit-test or both using Conan (which uses CMake in the background)  
Note: for running the built application/unit-test, the terminal has to be used  

Please check the documentation of the VS Code extensions used for details.  

### Using the Terminal
The sequence to build the application from scratch is as follows:
- Install the application dependencies using Conan
    ````bash
    conan install . --install-folder build/gcc --build missing
    ````
- Build the application using Conan
    ````bash
    conan build . --build-folder build/gcc
    ````
- Run the application
    ````bash
    ./build/gcc/bin/app
    ````
    Note: the application can be controlled via several environment variables and/or command line arguments.
          Run `./build/gcc/bin/app --help` for details
- Check the running application (from a new terminal)
    ````bash
    curl localhost:5000
    ````
    Note: the port number is controllable from environment variables and command line arguments. The value 5000 is the default  

The sequence to run the unit tests follow instructions similar to the above:
````bash
conan install . --install-folder build/gcc-test --build missing --options build_unittest=True
conan build . --build-folder build/gcc-test
./build/gcc-test/bin/test
````

## Running the Integration Test
__Important Note:__ since the integration test uses [Docker Compose](https://docs.docker.com/compose/), it has to be run __outside__ of the development container.  
The sequence to run the integration test is as follows:
- Change to the integration test directory
    ````bash
    cd tests/integration
    ````
- Build the integration test
    ````bash
    docker compose build
    ````
    Notes:
    * The above command assumes [Docker Compose V2](https://docs.docker.com/compose/#compose-v2-and-the-new-docker-compose-command). Alternatively for V1, the command would be `docker-compose build`
    * Although it is possible to build and run the integration test in one go (via `docker compose up --build`), it is recommended to split these steps in order to check for build errors more easily
- Run the integration test
    ````bash
    docker compose up
    ````
    Note: again, the above command assumes [Docker Compose V2](https://docs.docker.com/compose/#compose-v2-and-the-new-docker-compose-command). Alternatively for V1, the command would be `docker-compose up`
- Stop the integration test run by pressing `Ctrl+C`

## Using musl
The default conan profiles build against [glibc](https://www.gnu.org/software/libc/), however an additional profile and toolchain is included to statically build against [musl](https://www.musl-libc.org/).  
This enables the generation of a self-contained executable that can run on a [scratch](https://hub.docker.com/_/scratch) or [distroless/static](https://github.com/GoogleContainerTools/distroless/blob/main/base/README.md) base container image.  

Similar to the instructions in the previous section, building and running using musl can be done via the GUI or the terminal window.  

### Using the GUI
Follow the same previous instructions but choose one of the muslcc conan profiles

### Using the Terminal
Follow the same previous instructions but specify the build and host profiles as follows:
- For building and running the application
    ````bash
    conan install . \
        --profile:build default \
        --profile:host muslcc \
        --install-folder build/muslcc \
        --build missing
    conan build . --build-folder build/muslcc
    ./build/muslcc/bin/app
    ````
- For building and running the unit tests
    ````bash
    conan install . \
        --profile:build default \
        --profile:host muslcc \
        --install-folder build/muslcc-test \
        --build missing \
        --options build_unittest=True
    conan build . --build-folder build/muslcc-test
    ./build/muslcc-test/bin/test
    ````

### Running the Integration Test
Follow the same previous instructions but pass the necessary build arguments to build against musl and use a smaller runtime base image, i.e.,
````bash
docker compose build --build-arg CONAN_HOST_PROFILE=muslcc --build-arg BASE_RUNTIME_IMAGE=gcr.io/distroless/static-debian11:nonroot
````
Note: in case the above instruction is executed outside the Conti network, an additional build argument that skips the installation of the Conti CA cert can be provided, i.e., `--build-arg INSTALL_CONTI_CA_CERT=false`  
