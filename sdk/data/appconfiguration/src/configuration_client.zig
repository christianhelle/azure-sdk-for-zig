/// Azure App Configuration client.
///
/// Provides operations for managing configuration settings:
/// - Get, set, and delete configuration settings
/// - List settings with filters
/// - Lock/unlock settings
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const ConfigurationClient = struct {
    endpoint: []const u8,
    options: core.ClientOptions,

    const api_version = "2023-11-01";

    pub fn init(endpoint: []const u8, options: ?core.ClientOptions) ConfigurationClient {
        return .{
            .endpoint = endpoint,
            .options = options orelse core.ClientOptions.default,
        };
    }

    pub fn getApiVersion(self: *const ConfigurationClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for a specific setting.
    pub fn buildSettingUrl(self: *const ConfigurationClient, buf: []u8, key: []const u8, label: ?[]const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/kv/") catch return error.BufferTooSmall;
        writer.writeAll(key) catch return error.BufferTooSmall;
        writer.writeAll("?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        if (label) |l| {
            writer.writeAll("&label=") catch return error.BufferTooSmall;
            writer.writeAll(l) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Builds the URL for listing settings.
    pub fn buildListSettingsUrl(self: *const ConfigurationClient, buf: []u8, options: models.ListSettingsOptions) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/kv?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        if (options.key_filter) |kf| {
            writer.writeAll("&key=") catch return error.BufferTooSmall;
            writer.writeAll(kf) catch return error.BufferTooSmall;
        }
        if (options.label_filter) |lf| {
            writer.writeAll("&label=") catch return error.BufferTooSmall;
            writer.writeAll(lf) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Builds the request for getting a setting.
    pub fn buildGetSettingRequest(self: *const ConfigurationClient, buf: []u8, key: []const u8, label: ?[]const u8) !core.http.Request {
        const url = try self.buildSettingUrl(buf, key, label);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/vnd.microsoft.appconfig.kv+json");
        return req;
    }

    /// Builds the request for setting a configuration value.
    pub fn buildSetSettingRequest(self: *const ConfigurationClient, buf: []u8, key: []const u8, label: ?[]const u8) !core.http.Request {
        const url = try self.buildSettingUrl(buf, key, label);
        var req = core.http.Request.init(.PUT, url);
        try req.setHeader("Content-Type", "application/vnd.microsoft.appconfig.kv+json");
        try req.setHeader("Accept", "application/vnd.microsoft.appconfig.kv+json");
        return req;
    }

    /// Builds the request for deleting a setting.
    pub fn buildDeleteSettingRequest(self: *const ConfigurationClient, buf: []u8, key: []const u8, label: ?[]const u8) !core.http.Request {
        const url = try self.buildSettingUrl(buf, key, label);
        const req = core.http.Request.init(.DELETE, url);
        return req;
    }

    /// Builds the URL for locking a setting.
    pub fn buildLockSettingUrl(self: *const ConfigurationClient, buf: []u8, key: []const u8, label: ?[]const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/locks/") catch return error.BufferTooSmall;
        writer.writeAll(key) catch return error.BufferTooSmall;
        writer.writeAll("?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        if (label) |l| {
            writer.writeAll("&label=") catch return error.BufferTooSmall;
            writer.writeAll(l) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ConfigurationClient.init creates client" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    try std.testing.expectEqualStrings("https://my-config.azconfig.io", client.endpoint);
}

test "ConfigurationClient.getApiVersion returns default" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    try std.testing.expectEqualStrings("2023-11-01", client.getApiVersion());
}

test "ConfigurationClient.buildSettingUrl formats correctly" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildSettingUrl(&buf, "app:color", null);
    try std.testing.expectEqualStrings(
        "https://my-config.azconfig.io/kv/app:color?api-version=2023-11-01",
        url,
    );
}

test "ConfigurationClient.buildSettingUrl with label" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildSettingUrl(&buf, "app:color", "production");
    try std.testing.expect(std.mem.indexOf(u8, url, "&label=production") != null);
}

test "ConfigurationClient.buildListSettingsUrl formats correctly" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListSettingsUrl(&buf, .{});
    try std.testing.expectEqualStrings(
        "https://my-config.azconfig.io/kv?api-version=2023-11-01",
        url,
    );
}

test "ConfigurationClient.buildListSettingsUrl with filters" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListSettingsUrl(&buf, .{
        .key_filter = "app:*",
        .label_filter = "production",
    });
    try std.testing.expect(std.mem.indexOf(u8, url, "&key=app:*") != null);
    try std.testing.expect(std.mem.indexOf(u8, url, "&label=production") != null);
}

test "ConfigurationClient.buildGetSettingRequest creates GET request" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildGetSettingRequest(&buf, "app:color", null);
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "ConfigurationClient.buildSetSettingRequest creates PUT request" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildSetSettingRequest(&buf, "app:color", null);
    try std.testing.expectEqual(core.http.Method.PUT, req.method);
}

test "ConfigurationClient.buildDeleteSettingRequest creates DELETE request" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteSettingRequest(&buf, "app:color", null);
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}

test "ConfigurationClient.buildLockSettingUrl formats correctly" {
    const client = ConfigurationClient.init("https://my-config.azconfig.io", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildLockSettingUrl(&buf, "app:color", null);
    try std.testing.expectEqualStrings(
        "https://my-config.azconfig.io/locks/app:color?api-version=2023-11-01",
        url,
    );
}
