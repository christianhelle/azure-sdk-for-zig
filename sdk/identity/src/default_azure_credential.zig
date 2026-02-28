/// The recommended credential for most Azure SDK authentication scenarios.
///
/// Attempts authentication using the following credential chain:
/// 1. EnvironmentCredential
/// 2. ManagedIdentityCredential
/// 3. AzureCliCredential
///
/// Returns the first token that is successfully obtained.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

const EnvironmentCredential = @import("environment_credential.zig").EnvironmentCredential;
const ManagedIdentityCredential = @import("managed_identity_credential.zig").ManagedIdentityCredential;
const AzureCliCredential = @import("azure_cli_credential.zig").AzureCliCredential;
const ChainedTokenCredential = @import("chained_token_credential.zig").ChainedTokenCredential;

pub const DefaultAzureCredential = struct {
    env_cred: EnvironmentCredential,
    managed_cred: ManagedIdentityCredential,
    cli_cred: AzureCliCredential,
    chain: ChainedTokenCredential,

    pub fn init() !DefaultAzureCredential {
        var self = DefaultAzureCredential{
            .env_cred = EnvironmentCredential.init(),
            .managed_cred = ManagedIdentityCredential.init(),
            .cli_cred = AzureCliCredential.init(),
            .chain = ChainedTokenCredential.init(),
        };

        if (self.env_cred.isAvailable()) {
            try self.chain.addCredential(self.env_cred.tokenCredential());
        }
        try self.chain.addCredential(self.managed_cred.tokenCredential());
        try self.chain.addCredential(self.cli_cred.tokenCredential());

        return self;
    }

    /// Returns this credential as a `TokenCredential` interface.
    pub fn tokenCredential(self: *DefaultAzureCredential) TokenCredential {
        return self.chain.tokenCredential();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "DefaultAzureCredential.init creates credential chain" {
    var cred = try DefaultAzureCredential.init();
    _ = &cred;
    // Should have at least managed identity + CLI credentials
    try std.testing.expect(cred.chain.credential_count >= 2);
}
