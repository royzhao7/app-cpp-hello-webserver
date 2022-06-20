#include <cstdint>
#include <string>

#include <spdlog/spdlog.h>

class app_args
{
public:
    // Constructor will check for set environment variables then parse commandline args,
    // but might exit app on exception or if --help/--version called
    app_args(int argc, const char* argv[]);
    ~app_args() {}
    // Getters for application arguments
    std::uint16_t get_port_number() const;
    spdlog::level::level_enum get_spdlog_level() const;
    std::uint32_t get_cycle_time() const;
    const std::string& get_mount_dir() const;
private:
    // Application arguments with default values
    std::uint16_t m_port_number { 5000 };
    spdlog::level::level_enum m_spdlog_level { spdlog::level::info };
    std::uint32_t m_cycle_time { 500 };
    std::string m_mount_dir { "./www" };
    // Environment variable names
    const std::string m_PORT_NUMBER = { "PORT" };
    const std::string m_SPDLOG_LEVEL = { "LOG_LEVEL" };
};
