cmake_minimum_required(VERSION 3.5)
project(cpp_hello_app)

option(BUILD_UNITTEST "Built unit tests only" OFF)

# Import dependencies via conan
include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

file(GLOB APP_SOURCES src/*.cpp)
set(APP_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/inc/)

if(BUILD_UNITTEST)
    # Exclude main.cpp from app sources for unit testing
    list(FILTER APP_SOURCES EXCLUDE REGEX ".*/src/main.cpp$")
    add_subdirectory(tests/unit)
else()
    add_executable(app ${APP_SOURCES})
    target_include_directories(app PRIVATE ${APP_INCLUDES})
    target_link_libraries(app ${CONAN_LIBS})
    add_custom_target(www ALL
        COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/www ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/www
    )
endif()
