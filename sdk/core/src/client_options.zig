/// Azure SDK client options.
///
/// Base configuration shared by all Azure service clients.
/// Controls retry behavior, pipeline policies, and cloud environment.
const cloud_mod = @import("cloud.zig");
const retry_mod = @import("http/retry.zig");

pub const ClientOptions = struct {
    /// The cloud environment to use (default: Azure Public Cloud).
    cloud: cloud_mod.Cloud = cloud_mod.Cloud.azure_public,
    /// Retry policy configuration.
    retry: retry_mod.RetryPolicy = retry_mod.RetryPolicy.default,
    /// Custom API version override (null = use SDK default).
    api_version: ?[]const u8 = null,

    /// Returns the default client options.
    pub const default = ClientOptions{};
};

const std = @import("std");

// ── Tests ────────────────────────────────────────────────────────
test "ClientOptions.default uses public cloud" {
    const opts = ClientOptions.default;
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com",
        opts.cloud.active_directory_authority_url,
    );
}

test "ClientOptions.default uses default retry policy" {
    const opts = ClientOptions.default;
    try std.testing.expectEqual(@as(u32, 3), opts.retry.max_retries);
}

test "ClientOptions can be customized" {
    const opts = ClientOptions{
        .cloud = cloud_mod.Cloud.azure_china,
        .retry = .{ .max_retries = 5 },
        .api_version = "2024-01-01",
    };
    try std.testing.expectEqualStrings(
        "https://login.chinacloudapi.cn",
        opts.cloud.active_directory_authority_url,
    );
    try std.testing.expectEqual(@as(u32, 5), opts.retry.max_retries);
    try std.testing.expectEqualStrings("2024-01-01", opts.api_version.?);
}
