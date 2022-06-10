#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "app_args.h"

TEST(TestAppArgs, TestDefaultValues)
{
    const char* cmd_args[] = { "app" };
    app_args test_args(1, cmd_args);
    EXPECT_EQ(test_args.get_port_number(), 5000);
    EXPECT_EQ(test_args.get_spdlog_level(), spdlog::level::info);
    EXPECT_EQ(test_args.get_cycle_time(), 500);
    EXPECT_EQ(test_args.get_mount_dir(), "./www");
}

TEST(TestAppArgs, TestEnvVars)
{
    setenv("PORT", "4000", 1);
    setenv("LOG_LEVEL", "trace", 1);
    const char* cmd_args[] = { "app" };
    app_args test_args(1, cmd_args);
    EXPECT_EQ(test_args.get_port_number(), 4000);
    EXPECT_EQ(test_args.get_spdlog_level(), spdlog::level::trace);
    EXPECT_EQ(test_args.get_cycle_time(), 500);
    EXPECT_EQ(test_args.get_mount_dir(), "./www");
}

TEST(TestAppArgs, TestCmdLine)
{
    setenv("PORT", "4000", 1);
    setenv("LOG_LEVEL", "trace", 1);
    const char* cmd_args[] = {
        "app",
        "--port",
        "6000",
        "--log-level",
        "warning",
        "--cycle-time",
        "200",
        "--mount-dir",
        "./"
    };
    app_args test_args(9, cmd_args);
    EXPECT_EQ(test_args.get_port_number(), 6000);
    EXPECT_EQ(test_args.get_spdlog_level(), spdlog::level::warn);
    EXPECT_EQ(test_args.get_cycle_time(), 200);
    EXPECT_EQ(test_args.get_mount_dir(), "./");
}

TEST(TestAppArgs, TestInvMountDir)
{
    const char* cmd_args[] = {
        "app",
        "--mount-dir",
        "./xyz"
    };
    EXPECT_EXIT(app_args test_args(3, cmd_args), ::testing::ExitedWithCode(1), "value must name an existing directory");
}

TEST(TestAppArgs, TestHelpExit)
{
    const char* cmd_args[] = {
        "app",
        "--help"
    };
    ::testing::internal::CaptureStdout();
    EXPECT_EXIT(app_args test_args(2, cmd_args), ::testing::ExitedWithCode(0), "");
    EXPECT_THAT(::testing::internal::GetCapturedStdout(), ::testing::HasSubstr("USAGE:"));
}

TEST(TestAppArgs, TestVersionExit)
{
    const char* cmd_args[] = {
        "app",
        "--version"
    };
    ::testing::internal::CaptureStdout();
    EXPECT_EXIT(app_args test_args(2, cmd_args), ::testing::ExitedWithCode(0), "");
    EXPECT_THAT(::testing::internal::GetCapturedStdout(), ::testing::HasSubstr("version:"));
}
