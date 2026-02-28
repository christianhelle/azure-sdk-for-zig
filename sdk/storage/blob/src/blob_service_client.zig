/// Azure Blob Service client.
///
/// Provides account-level operations for Azure Blob Storage:
/// - List containers
/// - Create/delete containers
/// - Get account properties
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const BlobServiceClient = struct {
    account_url: []const u8,
    options: core.ClientOptions,

    const api_version = "2024-11-04";

    pub fn init(account_url: []const u8, options: ?core.ClientOptions) BlobServiceClient {
        return .{
            .account_url = account_url,
            .options = options orelse core.ClientOptions.default,
        };
    }

    /// Returns the API version used by this client.
    pub fn getApiVersion(self: *const BlobServiceClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for listing containers.
    pub fn buildListContainersUrl(self: *const BlobServiceClient, buf: []u8, options: models.ListContainersOptions) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeAll("/?comp=list") catch return error.BufferTooSmall;

        if (options.prefix) |prefix| {
            writer.writeAll("&prefix=") catch return error.BufferTooSmall;
            writer.writeAll(prefix) catch return error.BufferTooSmall;
        }
        if (options.max_results) |max| {
            writer.writeAll("&maxresults=") catch return error.BufferTooSmall;
            writer.print("{d}", .{max}) catch return error.BufferTooSmall;
        }
        if (options.marker) |marker| {
            writer.writeAll("&marker=") catch return error.BufferTooSmall;
            writer.writeAll(marker) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Builds the URL for creating/deleting a container.
    pub fn buildContainerUrl(self: *const BlobServiceClient, buf: []u8, container_name: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(container_name) catch return error.BufferTooSmall;
        writer.writeAll("?restype=container") catch return error.BufferTooSmall;

        return stream.getWritten();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "BlobServiceClient.init with default options" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", null);
    try std.testing.expectEqualStrings("https://myaccount.blob.core.windows.net", client.account_url);
}

test "BlobServiceClient.getApiVersion returns default version" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", null);
    try std.testing.expectEqualStrings("2024-11-04", client.getApiVersion());
}

test "BlobServiceClient.getApiVersion returns custom version" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", .{
        .api_version = "2023-01-01",
    });
    try std.testing.expectEqualStrings("2023-01-01", client.getApiVersion());
}

test "BlobServiceClient.buildListContainersUrl formats correctly" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", null);
    var buf: [512]u8 = undefined;
    const url = try client.buildListContainersUrl(&buf, .{});
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/?comp=list",
        url,
    );
}

test "BlobServiceClient.buildListContainersUrl with prefix" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", null);
    var buf: [512]u8 = undefined;
    const url = try client.buildListContainersUrl(&buf, .{ .prefix = "test" });
    try std.testing.expect(std.mem.indexOf(u8, url, "&prefix=test") != null);
}

test "BlobServiceClient.buildContainerUrl formats correctly" {
    const client = BlobServiceClient.init("https://myaccount.blob.core.windows.net", null);
    var buf: [512]u8 = undefined;
    const url = try client.buildContainerUrl(&buf, "my-container");
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/my-container?restype=container",
        url,
    );
}
