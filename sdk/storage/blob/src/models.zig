/// Azure Blob Storage data models.
///
/// Defines the types used to represent blobs, containers, and their properties.
const std = @import("std");

/// Access tier for a blob.
pub const AccessTier = enum {
    hot,
    cool,
    cold,
    archive,

    pub fn toString(self: AccessTier) []const u8 {
        return switch (self) {
            .hot => "Hot",
            .cool => "Cool",
            .cold => "Cold",
            .archive => "Archive",
        };
    }

    pub fn fromString(s: []const u8) ?AccessTier {
        if (std.ascii.eqlIgnoreCase(s, "Hot")) return .hot;
        if (std.ascii.eqlIgnoreCase(s, "Cool")) return .cool;
        if (std.ascii.eqlIgnoreCase(s, "Cold")) return .cold;
        if (std.ascii.eqlIgnoreCase(s, "Archive")) return .archive;
        return null;
    }
};

/// Type of blob.
pub const BlobType = enum {
    block_blob,
    page_blob,
    append_blob,

    pub fn toString(self: BlobType) []const u8 {
        return switch (self) {
            .block_blob => "BlockBlob",
            .page_blob => "PageBlob",
            .append_blob => "AppendBlob",
        };
    }

    pub fn fromString(s: []const u8) ?BlobType {
        if (std.mem.eql(u8, s, "BlockBlob")) return .block_blob;
        if (std.mem.eql(u8, s, "PageBlob")) return .page_blob;
        if (std.mem.eql(u8, s, "AppendBlob")) return .append_blob;
        return null;
    }
};

/// Lease status of a blob or container.
pub const LeaseStatus = enum {
    locked,
    unlocked,
};

/// Lease state of a blob or container.
pub const LeaseState = enum {
    available,
    leased,
    expired,
    breaking,
    broken,
};

/// Properties of a blob.
pub const BlobProperties = struct {
    content_length: u64 = 0,
    content_type: ?[]const u8 = null,
    content_encoding: ?[]const u8 = null,
    content_language: ?[]const u8 = null,
    content_md5: ?[]const u8 = null,
    etag: ?[]const u8 = null,
    last_modified: ?[]const u8 = null,
    blob_type: BlobType = .block_blob,
    access_tier: ?AccessTier = null,
    lease_status: ?LeaseStatus = null,
    lease_state: ?LeaseState = null,
};

/// Represents a single blob in a container.
pub const BlobItem = struct {
    name: []const u8,
    properties: BlobProperties = .{},
    deleted: bool = false,
};

/// Properties of a container.
pub const ContainerProperties = struct {
    etag: ?[]const u8 = null,
    last_modified: ?[]const u8 = null,
    lease_status: ?LeaseStatus = null,
    lease_state: ?LeaseState = null,
    has_immutability_policy: bool = false,
    has_legal_hold: bool = false,
};

/// Represents a single container in a storage account.
pub const ContainerItem = struct {
    name: []const u8,
    properties: ContainerProperties = .{},
};

/// Public access level for a container.
pub const PublicAccessLevel = enum {
    none,
    blob,
    container,

    pub fn toString(self: PublicAccessLevel) []const u8 {
        return switch (self) {
            .none => "",
            .blob => "blob",
            .container => "container",
        };
    }
};

/// Options for listing blobs.
pub const ListBlobsOptions = struct {
    prefix: ?[]const u8 = null,
    delimiter: ?[]const u8 = null,
    max_results: ?u32 = null,
    marker: ?[]const u8 = null,
};

/// Options for listing containers.
pub const ListContainersOptions = struct {
    prefix: ?[]const u8 = null,
    max_results: ?u32 = null,
    marker: ?[]const u8 = null,
};

/// Options for uploading a blob.
pub const UploadBlobOptions = struct {
    content_type: ?[]const u8 = null,
    access_tier: ?AccessTier = null,
    blob_type: BlobType = .block_blob,
};

/// Options for downloading a blob.
pub const DownloadBlobOptions = struct {
    range_start: ?u64 = null,
    range_end: ?u64 = null,
    if_match: ?[]const u8 = null,
};

// ── Tests ────────────────────────────────────────────────────────
test "AccessTier.toString returns correct strings" {
    try std.testing.expectEqualStrings("Hot", AccessTier.hot.toString());
    try std.testing.expectEqualStrings("Cool", AccessTier.cool.toString());
    try std.testing.expectEqualStrings("Cold", AccessTier.cold.toString());
    try std.testing.expectEqualStrings("Archive", AccessTier.archive.toString());
}

test "AccessTier.fromString parses correctly" {
    try std.testing.expectEqual(AccessTier.hot, AccessTier.fromString("Hot").?);
    try std.testing.expectEqual(AccessTier.cool, AccessTier.fromString("cool").?);
    try std.testing.expectEqual(AccessTier.cold, AccessTier.fromString("COLD").?);
    try std.testing.expectEqual(@as(?AccessTier, null), AccessTier.fromString("invalid"));
}

test "BlobType.toString returns correct strings" {
    try std.testing.expectEqualStrings("BlockBlob", BlobType.block_blob.toString());
    try std.testing.expectEqualStrings("PageBlob", BlobType.page_blob.toString());
    try std.testing.expectEqualStrings("AppendBlob", BlobType.append_blob.toString());
}

test "BlobType.fromString parses correctly" {
    try std.testing.expectEqual(BlobType.block_blob, BlobType.fromString("BlockBlob").?);
    try std.testing.expectEqual(BlobType.page_blob, BlobType.fromString("PageBlob").?);
    try std.testing.expectEqual(BlobType.append_blob, BlobType.fromString("AppendBlob").?);
    try std.testing.expectEqual(@as(?BlobType, null), BlobType.fromString("Invalid"));
}

test "BlobProperties has sensible defaults" {
    const props = BlobProperties{};
    try std.testing.expectEqual(@as(u64, 0), props.content_length);
    try std.testing.expectEqual(BlobType.block_blob, props.blob_type);
    try std.testing.expectEqual(@as(?[]const u8, null), props.content_type);
}

test "BlobItem can be constructed" {
    const blob = BlobItem{
        .name = "test.txt",
        .properties = .{ .content_length = 1024, .content_type = "text/plain" },
    };
    try std.testing.expectEqualStrings("test.txt", blob.name);
    try std.testing.expectEqual(@as(u64, 1024), blob.properties.content_length);
    try std.testing.expect(!blob.deleted);
}

test "ContainerItem can be constructed" {
    const container = ContainerItem{
        .name = "my-container",
        .properties = .{ .has_legal_hold = false },
    };
    try std.testing.expectEqualStrings("my-container", container.name);
}

test "PublicAccessLevel.toString returns correct strings" {
    try std.testing.expectEqualStrings("", PublicAccessLevel.none.toString());
    try std.testing.expectEqualStrings("blob", PublicAccessLevel.blob.toString());
    try std.testing.expectEqualStrings("container", PublicAccessLevel.container.toString());
}

test "ListBlobsOptions defaults" {
    const opts = ListBlobsOptions{};
    try std.testing.expectEqual(@as(?[]const u8, null), opts.prefix);
    try std.testing.expectEqual(@as(?u32, null), opts.max_results);
}

test "UploadBlobOptions defaults" {
    const opts = UploadBlobOptions{};
    try std.testing.expectEqual(BlobType.block_blob, opts.blob_type);
    try std.testing.expectEqual(@as(?[]const u8, null), opts.content_type);
}

test "DownloadBlobOptions defaults" {
    const opts = DownloadBlobOptions{};
    try std.testing.expectEqual(@as(?u64, null), opts.range_start);
    try std.testing.expectEqual(@as(?u64, null), opts.range_end);
}
