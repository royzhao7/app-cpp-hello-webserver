cmake_minimum_required(VERSION 3.15)
project(hello_webserver_test)

# For the gtest cmake macros
include(GoogleTest)

# Find unit test dependencies
find_package(GTest)

# Collect unit test sources
file(GLOB TEST_SOURCES src/*.cpp)
# Exclude main.cpp from app sources for unit testing
set(TEST_APP_SOURCES ${APP_SOURCES})
list(FILTER TEST_APP_SOURCES EXCLUDE REGEX ".*/src/main.cpp$")

# Build the unit test application
add_executable(test ${TEST_SOURCES} ${TEST_APP_SOURCES})
target_include_directories(test PRIVATE ${APP_INCLUDES})
target_link_libraries(test
    cpp-httplib::cpp-httplib
    spdlog::spdlog
    tclap::tclap
    gtest::gtest
)

gtest_discover_tests(test)
