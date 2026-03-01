/// Azure SDK for Zig — Cosmos DB module.
///
/// Provides client implementations for Azure Cosmos DB:
///
/// - **CosmosClient**: Manage databases, containers, items, queries, and stored procedures
/// - **models**: Data types for databases, containers, items, partition keys, consistency levels, etc.

pub const CosmosClient = @import("cosmos_client.zig").CosmosClient;
pub const models = @import("models.zig");

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("cosmos_client.zig");
    _ = @import("models.zig");
}
