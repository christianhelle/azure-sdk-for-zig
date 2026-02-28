/// Azure SDK for Zig — Core module.
///
/// Provides foundational types shared across all Azure SDK service clients:
///
/// - **HTTP primitives**: `Request`, `Response`, `Pipeline`, `RetryPolicy`
/// - **Authentication**: `TokenCredential`, `AccessToken`
/// - **Cloud environments**: `Cloud` (Public, China, Government)
/// - **Error handling**: Unified `Error` and `ErrorKind` types
/// - **Client configuration**: `ClientOptions`

/// HTTP request/response types and pipeline.
pub const http = struct {
    pub const Request = @import("http/request.zig").Request;
    pub const Method = @import("http/request.zig").Method;
    pub const Response = @import("http/response.zig").Response;
    pub const Pipeline = @import("http/pipeline.zig").Pipeline;
    pub const Policy = @import("http/pipeline.zig").Policy;
    pub const RetryPolicy = @import("http/retry.zig").RetryPolicy;
};

/// Authentication types.
pub const auth = struct {
    pub const TokenCredential = @import("auth/credentials.zig").TokenCredential;
    pub const AccessToken = @import("auth/credentials.zig").AccessToken;
    pub const TokenRequestOptions = @import("auth/credentials.zig").TokenRequestOptions;
};

/// Cloud environment configuration.
pub const Cloud = @import("cloud.zig").Cloud;

/// Error types for the Azure SDK.
pub const errors = @import("error.zig");
pub const Error = errors.Error;
pub const ErrorKind = errors.Kind;

/// Client configuration options.
pub const ClientOptions = @import("client_options.zig").ClientOptions;

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("http/request.zig");
    _ = @import("http/response.zig");
    _ = @import("http/pipeline.zig");
    _ = @import("http/retry.zig");
    _ = @import("auth/credentials.zig");
    _ = @import("cloud.zig");
    _ = @import("error.zig");
    _ = @import("client_options.zig");
}
