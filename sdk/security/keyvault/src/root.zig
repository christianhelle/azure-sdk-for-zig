/// Azure SDK for Zig — Key Vault module.
///
/// Provides client implementations for Azure Key Vault:
///
/// - **SecretClient**: Manage secrets (get, set, delete, list)
/// - **KeyClient**: Manage cryptographic keys (create, get, delete, list, crypto operations)
/// - **CertificateClient**: Manage certificates (get, create, delete, list)
/// - **models**: Data types for secrets, keys, and certificates

pub const SecretClient = @import("secret_client.zig").SecretClient;
pub const KeyClient = @import("key_client.zig").KeyClient;
pub const CertificateClient = @import("certificate_client.zig").CertificateClient;
pub const models = @import("models.zig");

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("secret_client.zig");
    _ = @import("key_client.zig");
    _ = @import("certificate_client.zig");
    _ = @import("models.zig");
}
