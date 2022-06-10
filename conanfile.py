from conans import ConanFile, CMake

class CppHelloConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    requires = [
        "cpp-httplib/0.7.5",
        "spdlog/1.7.0",
        "tclap/1.2.3"
    ]
    generators = "cmake"
    options = {
        "build_unittest": [True, False]
    }
    default_options = {
        "build_unittest": False
    }

    def requirements(self):
        if self.options.build_unittest:
            self.requires("gtest/1.10.0")
    
    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
