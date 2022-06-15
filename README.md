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
conan install . --install-folder build/gcc --build missing --options build_unittest=True
conan build . --build-folder build/gcc
./build/gcc/bin/test
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
