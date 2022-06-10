#include <cstdint>
#include <httplib.h>

namespace hello
{
    namespace server
    {
        class hello_server
        {
        public:
            hello_server(std::uint16_t port_number, const std::string& mount_dir);
            ~hello_server() {}
            void start();
            void stop();
        private:
            httplib::Server m_server;
        };
    }
}