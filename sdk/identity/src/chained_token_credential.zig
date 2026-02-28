/// Tries multiple credentials in order, returning the first successful token.
///
/// This is the building block for `DefaultAzureCredential` and can be used
/// to create custom credential chains.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

/// Maximum number of credentials in a chain.
const max_credentials = 8;

pub const ChainedTokenCredential = struct {
    credentials: [max_credentials]TokenCredential = undefined,
    credential_count: usize = 0,

    pub fn init() ChainedTokenCredential {
        return .{};
    }

    /// Adds a credential to the chain. Credentials are tried in the order added.
    pub fn addCredential(self: *ChainedTokenCredential, credential: TokenCredential) !void {
        if (self.credential_count >= max_credentials) return error.TooManyCredentials;
        self.credentials[self.credential_count] = credential;
        self.credential_count += 1;
    }

    /// Returns this credential chain as a `TokenCredential` interface.
    pub fn tokenCredential(self: *ChainedTokenCredential) TokenCredential {
        return .{
            .ptr = @ptrCast(self),
            .getTokenFn = @ptrCast(&getToken),
        };
    }

    fn getToken(self: *ChainedTokenCredential, options: TokenRequestOptions) !AccessToken {
        for (0..self.credential_count) |i| {
            const token = self.credentials[i].getToken(options) catch continue;
            return token;
        }
        return error.NoCredentialSucceeded;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ChainedTokenCredential.init creates empty chain" {
    const chain = ChainedTokenCredential.init();
    try std.testing.expectEqual(@as(usize, 0), chain.credential_count);
}

test "ChainedTokenCredential.addCredential increments count" {
    var chain = ChainedTokenCredential.init();
    // Create a mock credential
    const MockCred = struct {
        fn getToken(_: *anyopaque, _: TokenRequestOptions) !AccessToken {
            return error.HttpClientRequired;
        }
    };
    var dummy: u8 = 0;
    const cred = TokenCredential{
        .ptr = @ptrCast(&dummy),
        .getTokenFn = @ptrCast(&MockCred.getToken),
    };
    try chain.addCredential(cred);
    try std.testing.expectEqual(@as(usize, 1), chain.credential_count);
}
