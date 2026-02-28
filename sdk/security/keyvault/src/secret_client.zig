/// Azure Key Vault Secret client.
///
/// Provides operations for managing secrets in Azure Key Vault:
/// - Get, set, and delete secrets
/// - List secrets and secret versions
/// - Backup and restore secrets
const std = @import("std");
const core = @import("azure_core");

pub const SecretClient = struct {
    vault_url: []const u8,
    options: core.ClientOptions,

    const api_version = "7.5";

    pub fn init(vault_url: []const u8, options: ?core.ClientOptions) SecretClient {
        return .{
            .vault_url = vault_url,
            .options = options orelse core.ClientOptions.default,
        };
    }

    /// Returns the API version used by this client.
    pub fn getApiVersion(self: *const SecretClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for a specific secret.
    pub fn buildSecretUrl(self: *const SecretClient, buf: []u8, secret_name: []const u8, version: ?[]const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/secrets/") catch return error.BufferTooSmall;
        writer.writeAll(secret_name) catch return error.BufferTooSmall;

        if (version) |v| {
            writer.writeByte('/') catch return error.BufferTooSmall;
            writer.writeAll(v) catch return error.BufferTooSmall;
        }

        writer.writeAll("?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for listing secrets.
    pub fn buildListSecretsUrl(self: *const SecretClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/secrets?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for getting a secret value.
    pub fn buildGetSecretRequest(self: *const SecretClient, buf: []u8, secret_name: []const u8, version: ?[]const u8) !core.http.Request {
        const url = try self.buildSecretUrl(buf, secret_name, version);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/json");
        return req;
    }

    /// Builds the request for setting a secret.
    pub fn buildSetSecretRequest(self: *const SecretClient, buf: []u8, secret_name: []const u8) !core.http.Request {
        const url = try self.buildSecretUrl(buf, secret_name, null);
        var req = core.http.Request.init(.PUT, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        return req;
    }

    /// Builds the request for deleting a secret.
    pub fn buildDeleteSecretRequest(self: *const SecretClient, buf: []u8, secret_name: []const u8) !core.http.Request {
        const url = try self.buildSecretUrl(buf, secret_name, null);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("Accept", "application/json");
        return req;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "SecretClient.init creates client" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    try std.testing.expectEqualStrings("https://my-vault.vault.azure.net", client.vault_url);
}

test "SecretClient.getApiVersion returns default" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    try std.testing.expectEqualStrings("7.5", client.getApiVersion());
}

test "SecretClient.buildSecretUrl formats correctly" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildSecretUrl(&buf, "my-secret", null);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/secrets/my-secret?api-version=7.5",
        url,
    );
}

test "SecretClient.buildSecretUrl with version" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildSecretUrl(&buf, "my-secret", "abc123");
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/secrets/my-secret/abc123?api-version=7.5",
        url,
    );
}

test "SecretClient.buildListSecretsUrl formats correctly" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListSecretsUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/secrets?api-version=7.5",
        url,
    );
}

test "SecretClient.buildGetSecretRequest creates GET request" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildGetSecretRequest(&buf, "my-secret", null);
    try std.testing.expectEqual(core.http.Method.GET, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Accept").?);
}

test "SecretClient.buildSetSecretRequest creates PUT request" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildSetSecretRequest(&buf, "my-secret");
    try std.testing.expectEqual(core.http.Method.PUT, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);
}

test "SecretClient.buildDeleteSecretRequest creates DELETE request" {
    const client = SecretClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteSecretRequest(&buf, "my-secret");
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}
