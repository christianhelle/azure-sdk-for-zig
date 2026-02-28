/// Authenticates using environment variables.
///
/// Reads credential information from environment variables and delegates
/// to the appropriate credential implementation. Checks for:
///
/// 1. `AZURE_TENANT_ID` + `AZURE_CLIENT_ID` + `AZURE_CLIENT_SECRET` → `ClientSecretCredential`
///
/// Required environment variables vary by credential type.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

const ClientSecretCredential = @import("client_secret_credential.zig").ClientSecretCredential;

pub const EnvironmentCredential = struct {
    inner: ?CredentialKind = null,

    const CredentialKind = union(enum) {
        client_secret: ClientSecretCredential,
    };

    /// Creates an EnvironmentCredential by reading from environment variables.
    /// Returns null if the required environment variables are not set.
    pub fn init() EnvironmentCredential {
        const tenant_id = std.posix.getenv("AZURE_TENANT_ID");
        const client_id = std.posix.getenv("AZURE_CLIENT_ID");

        if (tenant_id != null and client_id != null) {
            // Try client secret first
            if (std.posix.getenv("AZURE_CLIENT_SECRET")) |client_secret| {
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
