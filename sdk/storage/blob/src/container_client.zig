/// Azure Blob Container client.
///
/// Provides container-level operations for Azure Blob Storage:
/// - List blobs
/// - Get container properties
/// - Set container metadata
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const ContainerClient = struct {
    account_url: []const u8,
    container_name: []const u8,
    options: core.ClientOptions,

    const api_version = "2024-11-04";

    pub fn init(account_url: []const u8, container_name: []const u8, options: ?core.ClientOptions) ContainerClient {
        return .{
            .account_url = account_url,
            .container_name = container_name,
            .options = options orelse core.ClientOptions.default,
        };
    }

    /// Returns the API version used by this client.
    pub fn getApiVersion(self: *const ContainerClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the base URL for this container.
    pub fn buildBaseUrl(self: *const ContainerClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(self.container_name) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for listing blobs in this container.
    pub fn buildListBlobsUrl(self: *const ContainerClient, buf: []u8, options: models.ListBlobsOptions) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(self.container_name) catch return error.BufferTooSmall;
        writer.writeAll("?restype=container&comp=list") catch return error.BufferTooSmall;

        if (options.prefix) |prefix| {
            writer.writeAll("&prefix=") catch return error.BufferTooSmall;
            writer.writeAll(prefix) catch return error.BufferTooSmall;
        }
        if (options.delimiter) |delimiter| {
            writer.writeAll("&delimiter=") catch return error.BufferTooSmall;
            writer.writeAll(delimiter) catch return error.BufferTooSmall;
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

    /// Builds the URL for a specific blob in this container.
    pub fn buildBlobUrl(self: *const ContainerClient, buf: []u8, blob_name: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(self.container_name) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(blob_name) catch return error.BufferTooSmall;

        return stream.getWritten();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ContainerClient.init creates client" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    try std.testing.expectEqualStrings("https://myaccount.blob.core.windows.net", client.account_url);
    try std.testing.expectEqualStrings("my-container", client.container_name);
}

test "ContainerClient.buildBaseUrl formats correctly" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildBaseUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/my-container",
        url,
    );
}

test "ContainerClient.buildListBlobsUrl formats correctly" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    var buf: [512]u8 = undefined;
    const url = try client.buildListBlobsUrl(&buf, .{});
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/my-container?restype=container&comp=list",
        url,
    );
}

test "ContainerClient.buildListBlobsUrl with options" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    var buf: [512]u8 = undefined;
    const url = try client.buildListBlobsUrl(&buf, .{
        .prefix = "logs/",
        .delimiter = "/",
        .max_results = 100,
    });
    try std.testing.expect(std.mem.indexOf(u8, url, "&prefix=logs/") != null);
    try std.testing.expect(std.mem.indexOf(u8, url, "&delimiter=/") != null);
    try std.testing.expect(std.mem.indexOf(u8, url, "&maxresults=100") != null);
}

test "ContainerClient.buildBlobUrl formats correctly" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildBlobUrl(&buf, "test.txt");
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/my-container/test.txt",
        url,
    );
}

test "ContainerClient.getApiVersion returns default" {
    const client = ContainerClient.init("https://myaccount.blob.core.windows.net", "my-container", null);
    try std.testing.expectEqualStrings("2024-11-04", client.getApiVersion());
}
