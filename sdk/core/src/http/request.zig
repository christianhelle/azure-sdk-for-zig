/// Azure SDK HTTP request representation.
///
/// Encapsulates an HTTP request with headers, query parameters, and body.
/// Used throughout the Azure SDK pipeline for building and sending requests.
const std = @import("std");

pub const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,
    HEAD,
    OPTIONS,

    pub fn toString(self: Method) []const u8 {
        return @tagName(self);
    }
};

/// Maximum number of headers a request can hold.
const max_headers = 32;
/// Maximum number of query parameters a request can hold.
const max_query_params = 32;

/// Represents an HTTP request to be sent through the pipeline.
pub const Request = struct {
    method: Method,
    url: []const u8,
    header_keys: [max_headers][]const u8 = undefined,
    header_values: [max_headers][]const u8 = undefined,
    header_count: usize = 0,
    query_keys: [max_query_params][]const u8 = undefined,
    query_values: [max_query_params][]const u8 = undefined,
    query_count: usize = 0,
    body: ?[]const u8 = null,

    pub fn init(method: Method, url: []const u8) Request {
        return .{
            .method = method,
            .url = url,
        };
    }

    pub fn setHeader(self: *Request, key: []const u8, value: []const u8) !void {
        // Update existing header if key matches
        for (0..self.header_count) |i| {
            if (std.mem.eql(u8, self.header_keys[i], key)) {
                self.header_values[i] = value;
                return;
            }
        }
        if (self.header_count >= max_headers) return error.TooManyHeaders;
        self.header_keys[self.header_count] = key;
        self.header_values[self.header_count] = value;
        self.header_count += 1;
    }

    pub fn getHeader(self: *const Request, key: []const u8) ?[]const u8 {
        for (0..self.header_count) |i| {
            if (std.mem.eql(u8, self.header_keys[i], key)) {
                return self.header_values[i];
            }
        }
        return null;
    }

    pub fn addQueryParam(self: *Request, key: []const u8, value: []const u8) !void {
        if (self.query_count >= max_query_params) return error.TooManyQueryParams;
        self.query_keys[self.query_count] = key;
        self.query_values[self.query_count] = value;
        self.query_count += 1;
    }

    pub fn setBody(self: *Request, body: []const u8) void {
        self.body = body;
    }

    /// Builds the full URL including query parameters into the provided buffer.
    pub fn buildUrl(self: *const Request, buf: []u8) ![]const u8 {
        if (self.query_count == 0) {
            if (self.url.len > buf.len) return error.BufferTooSmall;
            @memcpy(buf[0..self.url.len], self.url);
            return buf[0..self.url.len];
        }

        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();
        writer.writeAll(self.url) catch return error.BufferTooSmall;
        writer.writeByte('?') catch return error.BufferTooSmall;

        for (0..self.query_count) |i| {
            if (i > 0) writer.writeByte('&') catch return error.BufferTooSmall;
            writer.writeAll(self.query_keys[i]) catch return error.BufferTooSmall;
            writer.writeByte('=') catch return error.BufferTooSmall;
            writer.writeAll(self.query_values[i]) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "Request.init creates request with method and url" {
    const req = Request.init(.GET, "https://example.com");
    try std.testing.expectEqual(Method.GET, req.method);
    try std.testing.expectEqualStrings("https://example.com", req.url);
    try std.testing.expectEqual(@as(?[]const u8, null), req.body);
    try std.testing.expectEqual(@as(usize, 0), req.header_count);
}

test "Request.setHeader adds and updates headers" {
    var req = Request.init(.GET, "https://example.com");
    try req.setHeader("Content-Type", "application/json");
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);

    // Update existing header
    try req.setHeader("Content-Type", "text/plain");
    try std.testing.expectEqualStrings("text/plain", req.getHeader("Content-Type").?);
    try std.testing.expectEqual(@as(usize, 1), req.header_count);
}

test "Request.getHeader returns null for missing header" {
    const req = Request.init(.GET, "https://example.com");
    try std.testing.expectEqual(@as(?[]const u8, null), req.getHeader("X-Missing"));
}

test "Request.addQueryParam adds parameters" {
    var req = Request.init(.GET, "https://example.com/path");
    try req.addQueryParam("api-version", "2024-01-01");
    try req.addQueryParam("comp", "list");
    try std.testing.expectEqual(@as(usize, 2), req.query_count);
}

test "Request.buildUrl without query params returns base URL" {
    const req = Request.init(.GET, "https://example.com/path");
    var buf: [256]u8 = undefined;
    const url = try req.buildUrl(&buf);
    try std.testing.expectEqualStrings("https://example.com/path", url);
}

test "Request.buildUrl with query params appends them" {
    var req = Request.init(.GET, "https://example.com/path");
    try req.addQueryParam("api-version", "2024-01-01");
    try req.addQueryParam("comp", "list");
    var buf: [256]u8 = undefined;
    const url = try req.buildUrl(&buf);
    try std.testing.expectEqualStrings("https://example.com/path?api-version=2024-01-01&comp=list", url);
}

test "Request.setBody sets request body" {
    var req = Request.init(.POST, "https://example.com");
    req.setBody("{\"key\":\"value\"}");
    try std.testing.expectEqualStrings("{\"key\":\"value\"}", req.body.?);
}

test "Method.toString returns correct string" {
    try std.testing.expectEqualStrings("GET", Method.GET.toString());
    try std.testing.expectEqualStrings("POST", Method.POST.toString());
    try std.testing.expectEqualStrings("PUT", Method.PUT.toString());
    try std.testing.expectEqualStrings("DELETE", Method.DELETE.toString());
}
