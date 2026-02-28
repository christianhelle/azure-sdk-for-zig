/// Azure SDK for Zig — Identity module.
///
/// Provides credential implementations for authenticating with Azure services:
///
/// - **ClientSecretCredential**: Authenticates using a client ID and secret
/// - **EnvironmentCredential**: Reads credentials from environment variables
/// - **AzureCliCredential**: Uses the Azure CLI for authentication
/// - **ManagedIdentityCredential**: For Azure-hosted resources (VMs, App Service, etc.)
/// - **ChainedTokenCredential**: Tries multiple credentials in order
/// - **DefaultAzureCredential**: The recommended "just works" credential chain
const core = @import("azure_core");

pub const ClientSecretCredential = @import("client_secret_credential.zig").ClientSecretCredential;
pub const EnvironmentCredential = @import("environment_credential.zig").EnvironmentCredential;
pub const AzureCliCredential = @import("azure_cli_credential.zig").AzureCliCredential;
pub const ManagedIdentityCredential = @import("managed_identity_credential.zig").ManagedIdentityCredential;
pub const ChainedTokenCredential = @import("chained_token_credential.zig").ChainedTokenCredential;
pub const DefaultAzureCredential = @import("default_azure_credential.zig").DefaultAzureCredential;

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("client_secret_credential.zig");
    _ = @import("environment_credential.zig");
    _ = @import("azure_cli_credential.zig");
    _ = @import("managed_identity_credential.zig");
    _ = @import("chained_token_credential.zig");
    _ = @import("default_azure_credential.zig");
}
