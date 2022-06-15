cmake_minimum_required(VERSION 3.15)
project(hello_webserver_app)

# Global settings for ease of collecting output binaries and dynamic libraries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Find dependencies
find_package(cpp-httplib)
find_package(spdlog)
find_package(tclap)

# Collect application sources
file(GLOB APP_SOURCES src/*.cpp)
set(APP_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/inc/)

add_executable(app ${APP_SOURCES})
target_include_directories(app PRIVATE ${APP_INCLUDES})
target_link_libraries(app
    cpp-httplib::cpp-httplib
    spdlog::spdlog
    tclap::tclap
)
add_custom_target(www ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/www ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/www
)

if (BUILD_TESTING)
    add_subdirectory(tests/unit)
endif()
