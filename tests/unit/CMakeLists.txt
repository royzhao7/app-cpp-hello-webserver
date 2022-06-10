cmake_minimum_required(VERSION 3.5)
project(cpp_hello_unittest)

# Import dependencies via conan
include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
conan_basic_setup()

file(GLOB TEST_SOURCES src/*.cpp)

add_executable(unittest ${TEST_SOURCES} ${APP_SOURCES})
target_include_directories(unittest PRIVATE ${APP_INCLUDES})
target_link_libraries(unittest ${CONAN_LIBS})

add_custom_target(www ALL
COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/www ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/www
)
