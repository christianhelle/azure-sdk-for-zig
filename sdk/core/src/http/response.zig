/// Azure SDK HTTP response representation.
///
/// Encapsulates an HTTP response with status, headers, and body.
const std = @import("std");

pub const Response = struct {
    status_code: u16,
    header_keys: std.ArrayListUnmanaged([]const u8),
    header_values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, status_code: u16) Response {
        return .{
            .status_code = status_code,
            .header_keys = .empty,
            .header_values = .empty,
            .body = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Response) void {
        self.header_keys.deinit(self.allocator);
        self.header_values.deinit(self.allocator);
        self.body.deinit(self.allocator);
    }

    pub fn addHeader(self: *Response, key: []const u8, value: []const u8) !void {
        try self.header_keys.append(self.allocator, key);
        try self.header_values.append(self.allocator, value);
    }

    pub fn getHeader(self: *const Response, key: []const u8) ?[]const u8 {
        for (self.header_keys.items, 0..) |k, i| {
            if (std.ascii.eqlIgnoreCase(k, key)) {
                return self.header_values.items[i];
            }
        }
        return null;
    }

    pub fn setBody(self: *Response, data: []const u8) !void {
        self.body.clearRetainingCapacity();
        try self.body.appendSlice(self.allocator, data);
    }

    pub fn getBody(self: *const Response) []const u8 {
        return self.body.items;
    }

    pub fn isSuccess(self: *const Response) bool {
        return self.status_code >= 200 and self.status_code < 300;
    }

    pub fn isRedirect(self: *const Response) bool {
        return self.status_code >= 300 and self.status_code < 400;
    }

    pub fn isClientError(self: *const Response) bool {
        return self.status_code >= 400 and self.status_code < 500;
    }

    pub fn isServerError(self: *const Response) bool {
        return self.status_code >= 500;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "Response.init creates response with status code" {
    var resp = Response.init(std.testing.allocator, 200);
    defer resp.deinit();
    try std.testing.expectEqual(@as(u16, 200), resp.status_code);
}

test "Response.isSuccess returns true for 2xx" {
    var resp = Response.init(std.testing.allocator, 200);
    defer resp.deinit();
    try std.testing.expect(resp.isSuccess());

    var resp2 = Response.init(std.testing.allocator, 204);
    defer resp2.deinit();
    try std.testing.expect(resp2.isSuccess());
}

test "Response.isSuccess returns false for non-2xx" {
    var resp = Response.init(std.testing.allocator, 404);
    defer resp.deinit();
    try std.testing.expect(!resp.isSuccess());
}

test "Response.isClientError returns true for 4xx" {
    var resp = Response.init(std.testing.allocator, 400);
    defer resp.deinit();
    try std.testing.expect(resp.isClientError());
}

test "Response.isServerError returns true for 5xx" {
    var resp = Response.init(std.testing.allocator, 500);
    defer resp.deinit();
    try std.testing.expect(resp.isServerError());
}

test "Response.isRedirect returns true for 3xx" {
    var resp = Response.init(std.testing.allocator, 301);
    defer resp.deinit();
    try std.testing.expect(resp.isRedirect());
}

test "Response.addHeader and getHeader work correctly" {
    var resp = Response.init(std.testing.allocator, 200);
    defer resp.deinit();
    try resp.addHeader("Content-Type", "application/json");
    try std.testing.expectEqualStrings("application/json", resp.getHeader("Content-Type").?);
    try std.testing.expectEqualStrings("application/json", resp.getHeader("content-type").?);
}

test "Response.getHeader returns null for missing header" {
    var resp = Response.init(std.testing.allocator, 200);
    defer resp.deinit();
    try std.testing.expectEqual(@as(?[]const u8, null), resp.getHeader("X-Missing"));
}

test "Response.setBody and getBody work correctly" {
    var resp = Response.init(std.testing.allocator, 200);
    defer resp.deinit();
    try resp.setBody("hello world");
    try std.testing.expectEqualStrings("hello world", resp.getBody());
}
