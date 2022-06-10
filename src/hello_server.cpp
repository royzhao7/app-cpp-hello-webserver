#include "hello_server.h"

#include <spdlog/spdlog.h>

hello::server::hello_server::hello_server(std::uint16_t port_number, const std::string& mount_dir)
{
    spdlog::debug("Using PORT={}", port_number);
    if (m_server.bind_to_port("0.0.0.0", port_number))
    {
        spdlog::debug("Bound to PORT {}", port_number);
        // Setup the endpoints
        m_server.Get("/text", [](const httplib::Request& request, httplib::Response& response) {
            spdlog::trace("Received request on /");
            response.set_content("Hello C++!\n", "text/plain");
        });
        m_server.set_mount_point("/", mount_dir.c_str());
    }
    else
    {
        spdlog::error("Failed to bind to PORT {}", port_number);
    }
}

void hello::server::hello_server::start()
{
    spdlog::debug("Starting server ...");
    // listen_after_bind will not return until stopped or failed
    if(!m_server.listen_after_bind())
    {
        spdlog::error("Failed to start server");
    }
}

void hello::server::hello_server::stop()
{
    if (m_server.is_running())
    {
        spdlog::debug("Stopping server ...");
        m_server.stop();
        spdlog::debug("Stopped server");
    }
}
