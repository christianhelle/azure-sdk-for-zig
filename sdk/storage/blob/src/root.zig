/// Azure SDK for Zig — Storage Blob module.
///
/// Provides client implementations for Azure Blob Storage:
///
/// - **BlobServiceClient**: Account-level operations (list/create/delete containers)
/// - **ContainerClient**: Container-level operations (list blobs, properties)
/// - **BlobClient**: Blob-level operations (upload, download, delete, properties)
/// - **models**: Data types for blobs, containers, and their properties

pub const BlobServiceClient = @import("blob_service_client.zig").BlobServiceClient;
pub const ContainerClient = @import("container_client.zig").ContainerClient;
pub const BlobClient = @import("blob_client.zig").BlobClient;
pub const models = @import("models.zig");

// ── Re-export sub-module tests ──────────────────────────────────
test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
    _ = @import("blob_service_client.zig");
    _ = @import("container_client.zig");
    _ = @import("blob_client.zig");
    _ = @import("models.zig");
}
