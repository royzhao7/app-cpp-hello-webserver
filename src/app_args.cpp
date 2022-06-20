#include <string>
#include <cstdlib>
#include <vector>

#include "app_args.h"
#include "app_args_constr.h"

#include <spdlog/spdlog.h>
#include <tclap/CmdLine.h>
#include <fmt/ranges.h>

app_args::app_args(int argc, const char* argv[])
{
    TCLAP::CmdLine cmd_line(
        "Note: The following environment variables are parsed by the application: "
        + m_PORT_NUMBER
        + ", " + m_SPDLOG_LEVEL
    );
    // Add port number argument
    TCLAP::ValueArg<std::uint16_t> port_number_arg(
        "",
        "port",
        fmt::format("Port number to listen to. Default: {}", m_port_number),
        false,
        m_port_number,
        "port number",
        cmd_line
    );
    // Add log level argument while constraining possible values
    std::vector<std::string> spdlog_values = SPDLOG_LEVEL_NAMES;
    TCLAP::ValuesConstraint<std::string> spdlog_constr (spdlog_values);
    TCLAP::ValueArg<std::string> log_level_arg(
        "",
        "log-level",
        fmt::format("Level for logging. Default: {}", spdlog::level::to_string_view(m_spdlog_level)),
        false,
        spdlog::level::to_short_c_str(m_spdlog_level),
        &spdlog_constr,
        cmd_line
    );
    // Add cycle time argument
    TCLAP::ValueArg<std::uint32_t> cycle_time_arg(
        "",
        "cycle-time",
        fmt::format("Periodic cycle time in ms for main application loop. Default: {}", m_cycle_time),
        false,
        m_cycle_time,
        "time ms",
        cmd_line
    );
    // Add the mount directory argument while constraining to valid paths
    os_dir_constr mount_dir_constr;
    TCLAP::ValueArg<std::string> mount_dir_arg(
        "",
        "mount-dir",
        fmt::format("mount directory where {}. Default: {}", mount_dir_constr.description(), m_mount_dir),
        false,
        m_mount_dir,
        &mount_dir_constr,
        cmd_line
    );
    // First assume values from environment then parse command line arguments to override, lastly do final checks
    try
    {
        // Note: reading of port environment variable will be attempted later due to need for string to uint16_t conversion handling
        m_spdlog_level = (std::getenv(m_SPDLOG_LEVEL.c_str()) != nullptr)? spdlog::level::from_str(std::getenv(m_SPDLOG_LEVEL.c_str())) : m_spdlog_level;
        // Then parse the command line arguments
        cmd_line.parse(argc, argv);
        // Update the values accordingly
        m_port_number = (port_number_arg.isSet())? port_number_arg.getValue() : m_port_number;
        m_spdlog_level = (log_level_arg.isSet())? spdlog::level::from_str(log_level_arg.getValue()) : m_spdlog_level;
        m_cycle_time = (cycle_time_arg.isSet())? cycle_time_arg.getValue() : m_cycle_time;
        m_mount_dir = (mount_dir_arg.isSet())? mount_dir_arg.getValue() : m_mount_dir;
        // Do any final checks in case values from environment are invalid and were not overriden by command line arguments
        // Check if log level was set from the environment variable
        if ((std::getenv(m_SPDLOG_LEVEL.c_str()) != nullptr) && (!log_level_arg.isSet()))
        {
            // Check if log level environment variable is a valid string
            if (!spdlog_constr.check(std::getenv(m_SPDLOG_LEVEL.c_str())))
            {
                throw TCLAP::ArgException("Invalid value", m_SPDLOG_LEVEL);
            }
        }
        // Check if port number has to be read from environment variable
        if ((std::getenv(m_PORT_NUMBER.c_str()) != nullptr) && (!port_number_arg.isSet()))
        {
            // Convert the port environment variable and perform checks
            try
            {
                const std::string str_port_num = std::getenv(m_PORT_NUMBER.c_str());
                std::size_t str_end = 0;
                // stoi might throw either a std::invalid_argument/std::out_of_range exception
                int port_num = std::stoi(str_port_num, &str_end);
                // If not the complete string was converted, or if the value is out of range, throw exception
                if (str_end != str_port_num.size())
                {
                    throw std::invalid_argument("");
                }
                if ( (port_num < 0) || (port_num > UINT16_MAX) )
                {
                    throw std::out_of_range("");
                }
                // Else update the port number
                m_port_number = (std::uint16_t)(port_num);
            }
            catch(const std::invalid_argument &e)
            {
                throw TCLAP::ArgException("Invalid value", m_PORT_NUMBER);
            }
            catch(const std::out_of_range &e)
            {
                throw TCLAP::ArgException("Invalid range", m_PORT_NUMBER);
            }
        }
        // Check if mount dir was not specified from the command line
        if (!mount_dir_arg.isSet())
        {
            // Check if the default mount dir value points to a valid directory
            if (!mount_dir_constr.check(m_mount_dir))
            {
                std::cerr << "Error mounting default directory: " << m_mount_dir << ". Directory does not exist" << std::endl;
                cmd_line.getOutput()->usage(cmd_line);
                throw TCLAP::ExitException(1);
            }
        }
    }
    catch(const TCLAP::ArgException &arg_except)
    {
        std::cerr << "Error parsing environment variable: " << arg_except.argId() << ". Details: " << arg_except.error() << std::endl;
        cmd_line.getOutput()->usage(cmd_line);
        std::exit(1);
    }
    catch(const TCLAP::ExitException &exit_except)
    {
        std::exit(exit_except.getExitStatus());
    }
}

std::uint16_t app_args::get_port_number() const
{
    return m_port_number;
}

spdlog::level::level_enum app_args::get_spdlog_level() const
{
    return m_spdlog_level;
}

std::uint32_t app_args::get_cycle_time() const
{
    return m_cycle_time;
}

const std::string& app_args::get_mount_dir() const
{
    return m_mount_dir;
}
