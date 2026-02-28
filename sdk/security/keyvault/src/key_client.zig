/// Azure Key Vault Key client.
///
/// Provides operations for managing cryptographic keys in Azure Key Vault:
/// - Create, get, and delete keys
/// - List keys and key versions
/// - Key operations (encrypt, decrypt, sign, verify, wrap, unwrap)
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const KeyClient = struct {
    vault_url: []const u8,
    options: core.ClientOptions,

    const api_version = "7.5";

    pub fn init(vault_url: []const u8, options: ?core.ClientOptions) KeyClient {
        return .{
            .vault_url = vault_url,
            .options = options orelse core.ClientOptions.default,
        };
    }

    pub fn getApiVersion(self: *const KeyClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for a specific key.
    pub fn buildKeyUrl(self: *const KeyClient, buf: []u8, key_name: []const u8, version: ?[]const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/keys/") catch return error.BufferTooSmall;
        writer.writeAll(key_name) catch return error.BufferTooSmall;

        if (version) |v| {
            writer.writeByte('/') catch return error.BufferTooSmall;
            writer.writeAll(v) catch return error.BufferTooSmall;
        }

        writer.writeAll("?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for listing keys.
    pub fn buildListKeysUrl(self: *const KeyClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/keys?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for creating a key.
    pub fn buildCreateKeyRequest(self: *const KeyClient, buf: []u8, key_name: []const u8) !core.http.Request {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/keys/") catch return error.BufferTooSmall;
        writer.writeAll(key_name) catch return error.BufferTooSmall;
        writer.writeAll("/create?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        const url = stream.getWritten();
        var req = core.http.Request.init(.POST, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        return req;
    }

    /// Builds the request for deleting a key.
    pub fn buildDeleteKeyRequest(self: *const KeyClient, buf: []u8, key_name: []const u8) !core.http.Request {
        const url = try self.buildKeyUrl(buf, key_name, null);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("Accept", "application/json");
        return req;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "KeyClient.init creates client" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    try std.testing.expectEqualStrings("https://my-vault.vault.azure.net", client.vault_url);
}

test "KeyClient.buildKeyUrl formats correctly" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildKeyUrl(&buf, "my-key", null);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/keys/my-key?api-version=7.5",
        url,
    );
}

test "KeyClient.buildKeyUrl with version" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildKeyUrl(&buf, "my-key", "v1");
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/keys/my-key/v1?api-version=7.5",
        url,
    );
}

test "KeyClient.buildListKeysUrl formats correctly" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListKeysUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/keys?api-version=7.5",
        url,
    );
}

test "KeyClient.buildCreateKeyRequest creates POST request" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateKeyRequest(&buf, "my-key");
    try std.testing.expectEqual(core.http.Method.POST, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);
}

test "KeyClient.buildDeleteKeyRequest creates DELETE request" {
    const client = KeyClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteKeyRequest(&buf, "my-key");
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}
