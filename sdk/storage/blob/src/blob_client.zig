/// Azure Blob client.
///
/// Provides blob-level operations for Azure Blob Storage:
/// - Upload/download blobs
/// - Delete blobs
/// - Get/set blob properties and metadata
/// - Manage blob snapshots and leases
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const BlobClient = struct {
    account_url: []const u8,
    container_name: []const u8,
    blob_name: []const u8,
    options: core.ClientOptions,

    const api_version = "2024-11-04";

    pub fn init(
        account_url: []const u8,
        container_name: []const u8,
        blob_name: []const u8,
        options: ?core.ClientOptions,
    ) BlobClient {
        return .{
            .account_url = account_url,
            .container_name = container_name,
            .blob_name = blob_name,
            .options = options orelse core.ClientOptions.default,
        };
    }

    /// Returns the API version used by this client.
    pub fn getApiVersion(self: *const BlobClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for this blob.
    pub fn buildUrl(self: *const BlobClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.account_url) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(self.container_name) catch return error.BufferTooSmall;
        writer.writeByte('/') catch return error.BufferTooSmall;
        writer.writeAll(self.blob_name) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for getting blob properties.
    pub fn buildGetPropertiesUrl(self: *const BlobClient, buf: []u8) ![]const u8 {
        // Properties are retrieved from a HEAD request to the blob URL
        return self.buildUrl(buf);
    }

    /// Builds the request for uploading a blob.
    pub fn buildUploadRequest(self: *const BlobClient, buf: []u8, options: models.UploadBlobOptions) !core.http.Request {
        const url = try self.buildUrl(buf);
        var req = core.http.Request.init(.PUT, url);
        try req.setHeader("x-ms-version", self.getApiVersion());
        try req.setHeader("x-ms-blob-type", options.blob_type.toString());

        if (options.content_type) |ct| {
            try req.setHeader("Content-Type", ct);
        }
        if (options.access_tier) |tier| {
            try req.setHeader("x-ms-access-tier", tier.toString());
        }

        return req;
    }

    /// Builds the request for downloading a blob.
    pub fn buildDownloadRequest(self: *const BlobClient, url_buf: []u8, options: models.DownloadBlobOptions) !core.http.Request {
        const url = try self.buildUrl(url_buf);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.range_start != null or options.range_end != null) {
            var range_buf: [64]u8 = undefined;
            var range_stream = std.io.fixedBufferStream(&range_buf);
            const range_writer = range_stream.writer();
            range_writer.writeAll("bytes=") catch {};
            if (options.range_start) |start| {
                range_writer.print("{d}", .{start}) catch {};
            }
            range_writer.writeByte('-') catch {};
            if (options.range_end) |end| {
                range_writer.print("{d}", .{end}) catch {};
            }
            try req.setHeader("x-ms-range", range_stream.getWritten());
        }

        return req;
    }

    /// Builds the request for deleting a blob.
    pub fn buildDeleteRequest(self: *const BlobClient, url_buf: []u8) !core.http.Request {
        const url = try self.buildUrl(url_buf);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("x-ms-version", self.getApiVersion());
        return req;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "BlobClient.init creates client" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "test.txt",
        null,
    );
    try std.testing.expectEqualStrings("test.txt", client.blob_name);
}

test "BlobClient.buildUrl formats correctly" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "path/to/blob.txt",
        null,
    );
    var buf: [256]u8 = undefined;
    const url = try client.buildUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://myaccount.blob.core.windows.net/my-container/path/to/blob.txt",
        url,
    );
}

test "BlobClient.buildUploadRequest creates PUT request" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "test.txt",
        null,
    );
    var buf: [256]u8 = undefined;
    const req = try client.buildUploadRequest(&buf, .{
        .content_type = "text/plain",
        .access_tier = .hot,
    });
    try std.testing.expectEqual(core.http.Method.PUT, req.method);
    try std.testing.expectEqualStrings("text/plain", req.getHeader("Content-Type").?);
    try std.testing.expectEqualStrings("Hot", req.getHeader("x-ms-access-tier").?);
    try std.testing.expectEqualStrings("BlockBlob", req.getHeader("x-ms-blob-type").?);
}

test "BlobClient.buildDownloadRequest creates GET request" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "test.txt",
        null,
    );
    var buf: [256]u8 = undefined;
    const req = try client.buildDownloadRequest(&buf, .{});
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "BlobClient.buildDeleteRequest creates DELETE request" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "test.txt",
        null,
    );
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteRequest(&buf);
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}

test "BlobClient.getApiVersion returns default version" {
    const client = BlobClient.init(
        "https://myaccount.blob.core.windows.net",
        "my-container",
        "test.txt",
        null,
    );
    try std.testing.expectEqualStrings("2024-11-04", client.getApiVersion());
}
