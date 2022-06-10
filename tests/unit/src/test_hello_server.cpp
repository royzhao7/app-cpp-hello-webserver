#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include <spdlog/spdlog.h>

#include "hello_server.h"

TEST(TestHelloServer, TestConstr)
{
    spdlog::set_level(spdlog::level::debug);
    ::testing::internal::CaptureStdout();
    hello::server::hello_server test_server(5000, "./www");
    EXPECT_THAT(::testing::internal::GetCapturedStdout(), ::testing::HasSubstr("Bound to PORT 5000"));
    spdlog::set_level(spdlog::level::info);
}

// TODO: Add more test cases
