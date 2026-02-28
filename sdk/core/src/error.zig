/// Azure SDK Core error types.
///
/// Provides a unified error handling mechanism across all Azure SDK modules.
/// Errors are categorized by their origin (HTTP, authentication, client-side, etc.)
/// to enable precise error handling and meaningful error messages.
pub const Kind = enum {
    /// The request was invalid or malformed.
    bad_request,
    /// Authentication failed or credentials are invalid.
    authentication,
    /// The requested resource was not found.
    not_found,
    /// The request conflicts with the current state of the resource.
    conflict,
    /// Too many requests have been sent in a given time period.
    throttling,
    /// The server encountered an unexpected condition.
    server_error,
    /// The service is temporarily unavailable.
    service_unavailable,
    /// A timeout occurred while waiting for a response.
    timeout,
    /// An I/O error occurred during the request.
    io,
    /// An error occurred during data serialization or deserialization.
    data_conversion,
    /// The operation was cancelled.
    cancelled,
    /// An error not covered by other variants.
    other,

    pub fn isRetryable(self: Kind) bool {
        return switch (self) {
            .throttling, .server_error, .service_unavailable, .timeout, .io => true,
            else => false,
        };
    }
};

/// Represents an error returned by an Azure service or the SDK itself.
pub const Error = struct {
    kind: Kind,
    message: []const u8,
    status: ?u16 = null,

    pub fn format(self: Error, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("AzureError({s}): {s}", .{ @tagName(self.kind), self.message });
        if (self.status) |s| {
            try writer.print(" (HTTP {d})", .{s});
        }
    }

    pub fn isRetryable(self: Error) bool {
        return self.kind.isRetryable();
    }

    pub fn badRequest(message: []const u8) Error {
        return .{ .kind = .bad_request, .message = message, .status = 400 };
    }

    pub fn unauthorized(message: []const u8) Error {
        return .{ .kind = .authentication, .message = message, .status = 401 };
    }

    pub fn notFound(message: []const u8) Error {
        return .{ .kind = .not_found, .message = message, .status = 404 };
    }

    pub fn conflict(message: []const u8) Error {
        return .{ .kind = .conflict, .message = message, .status = 409 };
    }

    pub fn tooManyRequests(message: []const u8) Error {
        return .{ .kind = .throttling, .message = message, .status = 429 };
    }

    pub fn serverError(message: []const u8) Error {
        return .{ .kind = .server_error, .message = message, .status = 500 };
    }

    pub fn serviceUnavailable(message: []const u8) Error {
        return .{ .kind = .service_unavailable, .message = message, .status = 503 };
    }

    pub fn fromHttpStatus(status: u16, message: []const u8) Error {
        const kind: Kind = switch (status) {
            400 => .bad_request,
            401, 403 => .authentication,
            404 => .not_found,
            409 => .conflict,
            429 => .throttling,
            500 => .server_error,
            503 => .service_unavailable,
            504 => .timeout,
            else => .other,
        };
        return .{ .kind = kind, .message = message, .status = status };
    }
};

const std = @import("std");

// ── Tests ────────────────────────────────────────────────────────
test "Error.fromHttpStatus maps status codes correctly" {
    const cases = [_]struct { status: u16, expected: Kind }{
        .{ .status = 400, .expected = .bad_request },
        .{ .status = 401, .expected = .authentication },
        .{ .status = 403, .expected = .authentication },
        .{ .status = 404, .expected = .not_found },
        .{ .status = 409, .expected = .conflict },
        .{ .status = 429, .expected = .throttling },
        .{ .status = 500, .expected = .server_error },
        .{ .status = 503, .expected = .service_unavailable },
        .{ .status = 504, .expected = .timeout },
        .{ .status = 418, .expected = .other },
    };

    for (cases) |c| {
        const err = Error.fromHttpStatus(c.status, "test");
        try std.testing.expectEqual(c.expected, err.kind);
        try std.testing.expectEqual(c.status, err.status.?);
    }
}

test "Error.isRetryable returns correct values" {
    try std.testing.expect(Error.tooManyRequests("").isRetryable());
    try std.testing.expect(Error.serverError("").isRetryable());
    try std.testing.expect(Error.serviceUnavailable("").isRetryable());
    try std.testing.expect(!Error.badRequest("").isRetryable());
    try std.testing.expect(!Error.unauthorized("").isRetryable());
    try std.testing.expect(!Error.notFound("").isRetryable());
    try std.testing.expect(!Error.conflict("").isRetryable());
}

test "Error convenience constructors set correct status codes" {
    try std.testing.expectEqual(@as(u16, 400), Error.badRequest("").status.?);
    try std.testing.expectEqual(@as(u16, 401), Error.unauthorized("").status.?);
    try std.testing.expectEqual(@as(u16, 404), Error.notFound("").status.?);
    try std.testing.expectEqual(@as(u16, 409), Error.conflict("").status.?);
    try std.testing.expectEqual(@as(u16, 429), Error.tooManyRequests("").status.?);
    try std.testing.expectEqual(@as(u16, 500), Error.serverError("").status.?);
    try std.testing.expectEqual(@as(u16, 503), Error.serviceUnavailable("").status.?);
}

test "Kind.isRetryable identifies retryable kinds" {
    try std.testing.expect(Kind.throttling.isRetryable());
    try std.testing.expect(Kind.server_error.isRetryable());
    try std.testing.expect(Kind.service_unavailable.isRetryable());
    try std.testing.expect(Kind.timeout.isRetryable());
    try std.testing.expect(Kind.io.isRetryable());
    try std.testing.expect(!Kind.bad_request.isRetryable());
    try std.testing.expect(!Kind.authentication.isRetryable());
    try std.testing.expect(!Kind.not_found.isRetryable());
    try std.testing.expect(!Kind.conflict.isRetryable());
    try std.testing.expect(!Kind.data_conversion.isRetryable());
    try std.testing.expect(!Kind.cancelled.isRetryable());
    try std.testing.expect(!Kind.other.isRetryable());
}
