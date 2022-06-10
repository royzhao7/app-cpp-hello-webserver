#include <string>
#include <cstdlib>
#include <thread>
#include <chrono>
#include <atomic>
#include <csignal>

#include <spdlog/spdlog.h>

#include "app_args.h"
#include "hello_server.h"

// global defintions and variables
namespace
{
    std::atomic<bool> exit_app {false};
    // Register handlers to capture termination and interrupt signal requests
    const auto sigterm_handler = std::signal(SIGTERM, [](int) {
        spdlog::debug("Recevied SIGTERM request ...");
        exit_app = true;
    });
    const auto sigint_handler = std::signal(SIGINT, [](int) {
        spdlog::debug("Recevied SIGINT request ...");
        exit_app = true;
    });
}

int main(int argc, const char* argv[])
{
    app_args main_args(argc, argv);
    spdlog::set_level(main_args.get_spdlog_level());
    spdlog::info("Starting the application ...");
    {
        hello::server::hello_server my_hello_server(main_args.get_port_number(), main_args.get_mount_dir());
        // start server in a separate thread since start is a blocking API
        std::thread server_thread([&]() {
            my_hello_server.start();
        });
        do
        {
            auto next_timepoint = std::chrono::system_clock::now() + std::chrono::milliseconds(main_args.get_cycle_time());
            spdlog::trace("Going to sleep until next iteration ...");
            std::this_thread::sleep_until(next_timepoint);
        } while (!exit_app);
        // stop server and wait for other thread to be done
        my_hello_server.stop();
        server_thread.join();
    }
    spdlog::info("Stopping the application ...");
    return 0;
}
