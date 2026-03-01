/// Azure Cosmos DB data models.
///
/// Defines types for Cosmos DB databases, containers, items, and their properties.
const std = @import("std");

// ── Consistency Levels ──────────────────────────────────────────

/// Cosmos DB consistency levels.
pub const ConsistencyLevel = enum {
    strong,
    bounded_staleness,
    session,
    consistent_prefix,
    eventual,

    pub fn toString(self: ConsistencyLevel) []const u8 {
        return switch (self) {
            .strong => "Strong",
            .bounded_staleness => "BoundedStaleness",
            .session => "Session",
            .consistent_prefix => "ConsistentPrefix",
            .eventual => "Eventual",
        };
    }

    pub fn fromString(s: []const u8) ?ConsistencyLevel {
        if (std.ascii.eqlIgnoreCase(s, "Strong")) return .strong;
        if (std.ascii.eqlIgnoreCase(s, "BoundedStaleness")) return .bounded_staleness;
        if (std.ascii.eqlIgnoreCase(s, "Session")) return .session;
        if (std.ascii.eqlIgnoreCase(s, "ConsistentPrefix")) return .consistent_prefix;
        if (std.ascii.eqlIgnoreCase(s, "Eventual")) return .eventual;
        return null;
    }
};

// ── Indexing ────────────────────────────────────────────────────

/// Indexing mode for a Cosmos DB container.
pub const IndexingMode = enum {
    consistent,
    lazy,
    none,

    pub fn toString(self: IndexingMode) []const u8 {
        return switch (self) {
            .consistent => "consistent",
            .lazy => "lazy",
            .none => "none",
        };
    }
};

// ── Partition Key ───────────────────────────────────────────────

/// Partition key definition kind.
pub const PartitionKeyKind = enum {
    hash,
    range,
    multi_hash,

    pub fn toString(self: PartitionKeyKind) []const u8 {
        return switch (self) {
            .hash => "Hash",
            .range => "Range",
            .multi_hash => "MultiHash",
        };
    }
};

/// Partition key definition for a container.
pub const PartitionKeyDefinition = struct {
    /// The paths used for partitioning (e.g., "/tenantId").
    paths: [max_paths][]const u8 = undefined,
    path_count: usize = 0,
    kind: PartitionKeyKind = .hash,
    version: u32 = 2,

    const max_paths = 4;

    pub fn addPath(self: *PartitionKeyDefinition, path: []const u8) !void {
        if (self.path_count >= max_paths) return error.TooManyPaths;
        self.paths[self.path_count] = path;
        self.path_count += 1;
    }
};

// ── Database ────────────────────────────────────────────────────

/// Properties of a Cosmos DB database.
pub const DatabaseProperties = struct {
    id: []const u8,
    etag: ?[]const u8 = null,
    self_link: ?[]const u8 = null,
    rid: ?[]const u8 = null,
};

/// Options for creating a database.
pub const CreateDatabaseOptions = struct {
    /// Throughput in RU/s (null = use default/serverless).
    throughput: ?u32 = null,
    /// Auto-scale max throughput in RU/s.
    max_throughput: ?u32 = null,
};

// ── Container ───────────────────────────────────────────────────

/// Properties of a Cosmos DB container.
pub const ContainerProperties = struct {
    id: []const u8,
    partition_key: PartitionKeyDefinition = .{},
    indexing_mode: IndexingMode = .consistent,
    default_ttl: ?i32 = null,
    etag: ?[]const u8 = null,
    self_link: ?[]const u8 = null,
    rid: ?[]const u8 = null,
};

/// Options for creating a container.
pub const CreateContainerOptions = struct {
    throughput: ?u32 = null,
    max_throughput: ?u32 = null,
    default_ttl: ?i32 = null,
};

// ── Items ───────────────────────────────────────────────────────

/// Options for querying items.
pub const QueryOptions = struct {
    /// The SQL query string.
    query: []const u8,
    /// Maximum number of items to return per page.
    max_item_count: ?u32 = null,
    /// Enable cross-partition queries.
    enable_cross_partition: bool = true,
    /// Continuation token for pagination.
    continuation_token: ?[]const u8 = null,
    /// Partition key value for the query.
    partition_key: ?[]const u8 = null,
};

/// Options for creating/upserting an item.
pub const ItemOptions = struct {
    /// Partition key value for the item.
    partition_key: ?[]const u8 = null,
    /// ETag for conditional operations.
    if_match: ?[]const u8 = null,
    /// If true, upsert the item (create or replace).
    is_upsert: bool = false,
};

/// Options for reading an item.
pub const ReadItemOptions = struct {
    partition_key: ?[]const u8 = null,
    if_none_match: ?[]const u8 = null,
};

/// Options for deleting an item.
pub const DeleteItemOptions = struct {
    partition_key: ?[]const u8 = null,
    if_match: ?[]const u8 = null,
};

// ── Throughput ──────────────────────────────────────────────────

/// Throughput properties for a database or container.
pub const ThroughputProperties = struct {
    /// Manual throughput in RU/s.
    throughput: ?u32 = null,
    /// Auto-scale max throughput in RU/s.
    max_throughput: ?u32 = null,
};

// ── Stored Procedures / Triggers / UDFs ─────────────────────────

/// Trigger type.
pub const TriggerType = enum {
    pre,
    post,

    pub fn toString(self: TriggerType) []const u8 {
        return switch (self) {
            .pre => "Pre",
            .post => "Post",
        };
    }
};

/// Trigger operation.
pub const TriggerOperation = enum {
    all,
    create,
    update,
    delete,
    replace,

    pub fn toString(self: TriggerOperation) []const u8 {
        return switch (self) {
            .all => "All",
            .create => "Create",
            .update => "Update",
            .delete => "Delete",
            .replace => "Replace",
        };
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ConsistencyLevel.toString returns correct strings" {
    try std.testing.expectEqualStrings("Strong", ConsistencyLevel.strong.toString());
    try std.testing.expectEqualStrings("BoundedStaleness", ConsistencyLevel.bounded_staleness.toString());
    try std.testing.expectEqualStrings("Session", ConsistencyLevel.session.toString());
    try std.testing.expectEqualStrings("ConsistentPrefix", ConsistencyLevel.consistent_prefix.toString());
    try std.testing.expectEqualStrings("Eventual", ConsistencyLevel.eventual.toString());
}

test "ConsistencyLevel.fromString parses correctly" {
    try std.testing.expectEqual(ConsistencyLevel.strong, ConsistencyLevel.fromString("Strong").?);
    try std.testing.expectEqual(ConsistencyLevel.session, ConsistencyLevel.fromString("session").?);
    try std.testing.expectEqual(ConsistencyLevel.eventual, ConsistencyLevel.fromString("EVENTUAL").?);
    try std.testing.expectEqual(@as(?ConsistencyLevel, null), ConsistencyLevel.fromString("invalid"));
}

test "IndexingMode.toString returns correct strings" {
    try std.testing.expectEqualStrings("consistent", IndexingMode.consistent.toString());
    try std.testing.expectEqualStrings("lazy", IndexingMode.lazy.toString());
    try std.testing.expectEqualStrings("none", IndexingMode.none.toString());
}

test "PartitionKeyKind.toString returns correct strings" {
    try std.testing.expectEqualStrings("Hash", PartitionKeyKind.hash.toString());
    try std.testing.expectEqualStrings("Range", PartitionKeyKind.range.toString());
    try std.testing.expectEqualStrings("MultiHash", PartitionKeyKind.multi_hash.toString());
}

test "PartitionKeyDefinition.addPath works correctly" {
    var pk = PartitionKeyDefinition{};
    try pk.addPath("/tenantId");
    try std.testing.expectEqual(@as(usize, 1), pk.path_count);
    try std.testing.expectEqualStrings("/tenantId", pk.paths[0]);
}

test "PartitionKeyDefinition defaults" {
    const pk = PartitionKeyDefinition{};
    try std.testing.expectEqual(PartitionKeyKind.hash, pk.kind);
    try std.testing.expectEqual(@as(u32, 2), pk.version);
    try std.testing.expectEqual(@as(usize, 0), pk.path_count);
}

test "DatabaseProperties can be constructed" {
    const db = DatabaseProperties{ .id = "my-database" };
    try std.testing.expectEqualStrings("my-database", db.id);
    try std.testing.expectEqual(@as(?[]const u8, null), db.etag);
}

test "ContainerProperties has sensible defaults" {
    const props = ContainerProperties{ .id = "my-container" };
    try std.testing.expectEqualStrings("my-container", props.id);
    try std.testing.expectEqual(IndexingMode.consistent, props.indexing_mode);
    try std.testing.expectEqual(@as(?i32, null), props.default_ttl);
}

test "CreateDatabaseOptions defaults" {
    const opts = CreateDatabaseOptions{};
    try std.testing.expectEqual(@as(?u32, null), opts.throughput);
    try std.testing.expectEqual(@as(?u32, null), opts.max_throughput);
}

test "CreateContainerOptions defaults" {
    const opts = CreateContainerOptions{};
    try std.testing.expectEqual(@as(?u32, null), opts.throughput);
    try std.testing.expectEqual(@as(?i32, null), opts.default_ttl);
}

test "QueryOptions can be constructed" {
    const opts = QueryOptions{
        .query = "SELECT * FROM c WHERE c.type = 'user'",
        .max_item_count = 100,
        .partition_key = "tenant-1",
    };
    try std.testing.expectEqualStrings("SELECT * FROM c WHERE c.type = 'user'", opts.query);
    try std.testing.expectEqual(@as(?u32, 100), opts.max_item_count);
    try std.testing.expect(opts.enable_cross_partition);
}

test "ItemOptions defaults" {
    const opts = ItemOptions{};
    try std.testing.expectEqual(@as(?[]const u8, null), opts.partition_key);
    try std.testing.expect(!opts.is_upsert);
}

test "ReadItemOptions defaults" {
    const opts = ReadItemOptions{};
    try std.testing.expectEqual(@as(?[]const u8, null), opts.partition_key);
}

test "DeleteItemOptions defaults" {
    const opts = DeleteItemOptions{};
    try std.testing.expectEqual(@as(?[]const u8, null), opts.partition_key);
}

test "ThroughputProperties can be constructed" {
    const tp = ThroughputProperties{ .throughput = 400 };
    try std.testing.expectEqual(@as(?u32, 400), tp.throughput);
    try std.testing.expectEqual(@as(?u32, null), tp.max_throughput);
}

test "TriggerType.toString returns correct strings" {
    try std.testing.expectEqualStrings("Pre", TriggerType.pre.toString());
    try std.testing.expectEqualStrings("Post", TriggerType.post.toString());
}

test "TriggerOperation.toString returns correct strings" {
    try std.testing.expectEqualStrings("All", TriggerOperation.all.toString());
    try std.testing.expectEqualStrings("Create", TriggerOperation.create.toString());
    try std.testing.expectEqualStrings("Update", TriggerOperation.update.toString());
    try std.testing.expectEqualStrings("Delete", TriggerOperation.delete.toString());
    try std.testing.expectEqualStrings("Replace", TriggerOperation.replace.toString());
}
