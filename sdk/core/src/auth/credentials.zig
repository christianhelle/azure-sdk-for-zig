/// Azure SDK authentication credentials.
///
/// Defines the `TokenCredential` interface used by all Azure SDK clients
/// for obtaining authentication tokens. Implementations include
/// `ClientSecretCredential`, `AzureCliCredential`, etc.
const std = @import("std");

/// Represents an OAuth2 access token with its expiration time.
pub const AccessToken = struct {
    /// The bearer token string.
    token: []const u8,
    /// Token expiration time as Unix timestamp (seconds since epoch).
    expires_on: i64,

    /// Returns true if the token has expired or will expire within the
    /// given number of seconds.
    pub fn isExpired(self: AccessToken, buffer_seconds: i64) bool {
        const now = std.time.timestamp();
        return now >= (self.expires_on - buffer_seconds);
    }
};

/// Options for requesting a token.
pub const TokenRequestOptions = struct {
    /// The scopes required for the token.
    scopes: []const []const u8,
};

/// Interface for types that can provide Azure authentication tokens.
///
/// This is the core abstraction for authentication across all Azure SDK clients.
/// Implementations must provide a `getToken` function that returns an `AccessToken`.
pub const TokenCredential = struct {
    ptr: *anyopaque,
    getTokenFn: *const fn (ptr: *anyopaque, options: TokenRequestOptions) anyerror!AccessToken,

    /// Obtains an access token for the specified scopes.
    pub fn getToken(self: TokenCredential, options: TokenRequestOptions) !AccessToken {
        return self.getTokenFn(self.ptr, options);
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "AccessToken.isExpired returns true for expired tokens" {
    const token = AccessToken{
        .token = "test-token",
        .expires_on = std.time.timestamp() - 100,
    };
    try std.testing.expect(token.isExpired(0));
}

test "AccessToken.isExpired returns false for valid tokens" {
    const token = AccessToken{
        .token = "test-token",
        .expires_on = std.time.timestamp() + 3600,
    };
    try std.testing.expect(!token.isExpired(0));
}

test "AccessToken.isExpired respects buffer_seconds" {
    const token = AccessToken{
        .token = "test-token",
        .expires_on = std.time.timestamp() + 60,
    };
    // Token expires in 60s, but with 120s buffer it's considered expired
    try std.testing.expect(token.isExpired(120));
    // With 30s buffer, it's still valid
    try std.testing.expect(!token.isExpired(30));
}
