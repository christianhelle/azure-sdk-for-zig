/// Azure SDK for Zig — App Configuration module.
///
/// Provides client implementations for Azure App Configuration:
///
/// - **ConfigurationClient**: Manage configuration settings (get, set, delete, list, lock/unlock)
/// - **models**: Data types for configuration settings and feature flags

pub const ConfigurationClient = @import("configuration_client.zig").ConfigurationClient;
pub const models = @import("models.zig");

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("configuration_client.zig");
    _ = @import("models.zig");
}
