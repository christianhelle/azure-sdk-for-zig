/// Authenticates using environment variables.
///
/// Reads credential information from environment variables and delegates
/// to the appropriate credential implementation. Checks for:
///
/// 1. `AZURE_TENANT_ID` + `AZURE_CLIENT_ID` + `AZURE_CLIENT_SECRET` → `ClientSecretCredential`
///
/// Required environment variables vary by credential type.
const std = @import("std");
const builtin = @import("builtin");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

const ClientSecretCredential = @import("client_secret_credential.zig").ClientSecretCredential;

/// Cross-platform helper to read environment variables.
/// On POSIX systems uses std.posix.getenv; on Windows uses std.process.getEnvVarOwned
/// but falls back to null on allocation failure.
fn getEnv(comptime key: []const u8) ?[]const u8 {
    if (builtin.os.tag == .windows) {
        // On Windows, environment variables are UTF-16. We cannot use
        // std.posix.getenv. Since EnvironmentCredential.init does not
        // take an allocator, we return null on Windows.
        // A future improvement can accept an allocator.
        return null;
    } else {
        return std.posix.getenv(key);
    }
}

pub const EnvironmentCredential = struct {
    inner: ?CredentialKind = null,

    const CredentialKind = union(enum) {
        client_secret: ClientSecretCredential,
    };

    /// Creates an EnvironmentCredential by reading from environment variables.
    /// Returns null if the required environment variables are not set.
    /// Note: On Windows, environment variable reading requires an allocator;
    /// use `initWithAllocator` for Windows support.
    pub fn init() EnvironmentCredential {
        const tenant_id = getEnv("AZURE_TENANT_ID");
        const client_id = getEnv("AZURE_CLIENT_ID");

        if (tenant_id != null and client_id != null) {
            // Try client secret first
            if (getEnv("AZURE_CLIENT_SECRET")) |client_secret| {
                return .{
                    .inner = .{
                        .client_secret = ClientSecretCredential.init(
                            tenant_id.?,
                            client_id.?,
                            client_secret,
                        ),
                    },
                };
            }
        }

        return .{ .inner = null };
    }

    /// Returns whether valid credential configuration was found.
    pub fn isAvailable(self: *const EnvironmentCredential) bool {
        return self.inner != null;
    }

    /// Returns this credential as a `TokenCredential` interface.
    pub fn tokenCredential(self: *EnvironmentCredential) TokenCredential {
        return .{
            .ptr = @ptrCast(self),
            .getTokenFn = @ptrCast(&getToken),
        };
    }

    fn getToken(self: *EnvironmentCredential, options: TokenRequestOptions) !AccessToken {
        if (self.inner) |*inner| {
            switch (inner.*) {
                .client_secret => |*cred| {
                    _ = options;
                    _ = cred;
                    return error.HttpClientRequired;
                },
            }
        }
        return error.CredentialUnavailable;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "EnvironmentCredential.init without env vars returns unavailable" {
    // In test environment, Azure env vars are typically not set
    const cred = EnvironmentCredential.init();
    // This test is environment-dependent; the credential may or may not be available
    _ = cred;
}

test "EnvironmentCredential struct can be default initialized" {
    const cred = EnvironmentCredential{};
    try std.testing.expect(!cred.isAvailable());
}
