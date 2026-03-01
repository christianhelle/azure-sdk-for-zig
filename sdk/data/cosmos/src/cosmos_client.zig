/// Azure Cosmos DB client.
///
/// Provides operations for managing Cosmos DB resources:
/// - Databases: create, read, delete, list
/// - Containers: create, read, delete, list
/// - Items: create, read, upsert, replace, delete, query
/// - Stored procedures, triggers, and UDFs
const std = @import("std");
const core = @import("azure_core");
const models = @import("models.zig");

pub const CosmosClient = struct {
    endpoint: []const u8,
    options: core.ClientOptions,

    const api_version = "2018-12-31";

    pub fn init(endpoint: []const u8, options: ?core.ClientOptions) CosmosClient {
        return .{
            .endpoint = endpoint,
            .options = options orelse core.ClientOptions.default,
        };
    }

    pub fn getApiVersion(self: *const CosmosClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    // ── Database operations ──────────────────────────────────────

    /// Builds the URL for listing databases.
    pub fn buildListDatabasesUrl(self: *const CosmosClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs") catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for a specific database.
    pub fn buildDatabaseUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for creating a database.
    pub fn buildCreateDatabaseRequest(self: *const CosmosClient, buf: []u8, options: models.CreateDatabaseOptions) !core.http.Request {
        const url = try self.buildListDatabasesUrl(buf);
        var req = core.http.Request.init(.POST, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.throughput) |tp| {
            var tp_buf: [16]u8 = undefined;
            var tp_stream = std.io.fixedBufferStream(&tp_buf);
            tp_stream.writer().print("{d}", .{tp}) catch {};
            try req.setHeader("x-ms-offer-throughput", tp_stream.getWritten());
        }
        if (options.max_throughput) |mt| {
            var mt_buf: [64]u8 = undefined;
            var mt_stream = std.io.fixedBufferStream(&mt_buf);
            const mt_writer = mt_stream.writer();
            mt_writer.writeAll("{\"maxThroughput\":") catch {};
            mt_writer.print("{d}", .{mt}) catch {};
            mt_writer.writeByte('}') catch {};
            try req.setHeader("x-ms-cosmos-offer-autopilot-settings", mt_stream.getWritten());
        }

        return req;
    }

    /// Builds the request for getting a database.
    pub fn buildGetDatabaseRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8) !core.http.Request {
        const url = try self.buildDatabaseUrl(buf, database_id);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());
        return req;
    }

    /// Builds the request for deleting a database.
    pub fn buildDeleteDatabaseRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8) !core.http.Request {
        const url = try self.buildDatabaseUrl(buf, database_id);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("x-ms-version", self.getApiVersion());
        return req;
    }

    // ── Container operations ─────────────────────────────────────

    /// Builds the URL for listing containers in a database.
    pub fn buildListContainersUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls") catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for a specific container.
    pub fn buildContainerUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls/") catch return error.BufferTooSmall;
        writer.writeAll(container_id) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for creating a container.
    pub fn buildCreateContainerRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, options: models.CreateContainerOptions) !core.http.Request {
        const url = try self.buildListContainersUrl(buf, database_id);
        var req = core.http.Request.init(.POST, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.throughput) |tp| {
            var tp_buf: [16]u8 = undefined;
            var tp_stream = std.io.fixedBufferStream(&tp_buf);
            tp_stream.writer().print("{d}", .{tp}) catch {};
            try req.setHeader("x-ms-offer-throughput", tp_stream.getWritten());
        }

        return req;
    }

    /// Builds the request for getting a container.
    pub fn buildGetContainerRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8) !core.http.Request {
        const url = try self.buildContainerUrl(buf, database_id, container_id);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());
        return req;
    }

    /// Builds the request for deleting a container.
    pub fn buildDeleteContainerRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8) !core.http.Request {
        const url = try self.buildContainerUrl(buf, database_id, container_id);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("x-ms-version", self.getApiVersion());
        return req;
    }

    // ── Item operations ──────────────────────────────────────────

    /// Builds the URL for listing/creating items in a container.
    pub fn buildItemsUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls/") catch return error.BufferTooSmall;
        writer.writeAll(container_id) catch return error.BufferTooSmall;
        writer.writeAll("/docs") catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for a specific item.
    pub fn buildItemUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, item_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls/") catch return error.BufferTooSmall;
        writer.writeAll(container_id) catch return error.BufferTooSmall;
        writer.writeAll("/docs/") catch return error.BufferTooSmall;
        writer.writeAll(item_id) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for creating or upserting an item.
    pub fn buildCreateItemRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, options: models.ItemOptions) !core.http.Request {
        const url = try self.buildItemsUrl(buf, database_id, container_id);
        var req = core.http.Request.init(.POST, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.is_upsert) {
            try req.setHeader("x-ms-documentdb-is-upsert", "True");
        }
        if (options.partition_key) |pk| {
            try req.setHeader("x-ms-documentdb-partitionkey", pk);
        }

        return req;
    }

    /// Builds the request for reading an item.
    pub fn buildReadItemRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, item_id: []const u8, options: models.ReadItemOptions) !core.http.Request {
        const url = try self.buildItemUrl(buf, database_id, container_id, item_id);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.partition_key) |pk| {
            try req.setHeader("x-ms-documentdb-partitionkey", pk);
        }
        if (options.if_none_match) |etag| {
            try req.setHeader("If-None-Match", etag);
        }

        return req;
    }

    /// Builds the request for replacing an item.
    pub fn buildReplaceItemRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, item_id: []const u8, options: models.ItemOptions) !core.http.Request {
        const url = try self.buildItemUrl(buf, database_id, container_id, item_id);
        var req = core.http.Request.init(.PUT, url);
        try req.setHeader("Content-Type", "application/json");
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.partition_key) |pk| {
            try req.setHeader("x-ms-documentdb-partitionkey", pk);
        }
        if (options.if_match) |etag| {
            try req.setHeader("If-Match", etag);
        }

        return req;
    }

    /// Builds the request for deleting an item.
    pub fn buildDeleteItemRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, item_id: []const u8, options: models.DeleteItemOptions) !core.http.Request {
        const url = try self.buildItemUrl(buf, database_id, container_id, item_id);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("x-ms-version", self.getApiVersion());

        if (options.partition_key) |pk| {
            try req.setHeader("x-ms-documentdb-partitionkey", pk);
        }
        if (options.if_match) |etag| {
            try req.setHeader("If-Match", etag);
        }

        return req;
    }

    // ── Query operations ─────────────────────────────────────────

    /// Builds the request for querying items in a container.
    pub fn buildQueryRequest(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, options: models.QueryOptions) !core.http.Request {
        const url = try self.buildItemsUrl(buf, database_id, container_id);
        var req = core.http.Request.init(.POST, url);
        try req.setHeader("Content-Type", "application/query+json");
        try req.setHeader("Accept", "application/json");
        try req.setHeader("x-ms-version", self.getApiVersion());
        try req.setHeader("x-ms-documentdb-isquery", "True");

        if (options.enable_cross_partition) {
            try req.setHeader("x-ms-documentdb-query-enablecrosspartition", "True");
        }
        if (options.max_item_count) |max| {
            var max_buf: [16]u8 = undefined;
            var max_stream = std.io.fixedBufferStream(&max_buf);
            max_stream.writer().print("{d}", .{max}) catch {};
            try req.setHeader("x-ms-max-item-count", max_stream.getWritten());
        }
        if (options.continuation_token) |token| {
            try req.setHeader("x-ms-continuation", token);
        }
        if (options.partition_key) |pk| {
            try req.setHeader("x-ms-documentdb-partitionkey", pk);
        }

        return req;
    }

    // ── Stored Procedure operations ──────────────────────────────

    /// Builds the URL for stored procedures in a container.
    pub fn buildStoredProceduresUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls/") catch return error.BufferTooSmall;
        writer.writeAll(container_id) catch return error.BufferTooSmall;
        writer.writeAll("/sprocs") catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for a specific stored procedure.
    pub fn buildStoredProcedureUrl(self: *const CosmosClient, buf: []u8, database_id: []const u8, container_id: []const u8, sproc_id: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.endpoint) catch return error.BufferTooSmall;
        writer.writeAll("/dbs/") catch return error.BufferTooSmall;
        writer.writeAll(database_id) catch return error.BufferTooSmall;
        writer.writeAll("/colls/") catch return error.BufferTooSmall;
        writer.writeAll(container_id) catch return error.BufferTooSmall;
        writer.writeAll("/sprocs/") catch return error.BufferTooSmall;
        writer.writeAll(sproc_id) catch return error.BufferTooSmall;

        return stream.getWritten();
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "CosmosClient.init creates client" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    try std.testing.expectEqualStrings("https://my-cosmos.documents.azure.com", client.endpoint);
}

test "CosmosClient.getApiVersion returns default" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    try std.testing.expectEqualStrings("2018-12-31", client.getApiVersion());
}

test "CosmosClient.getApiVersion returns custom" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", .{
        .api_version = "2024-01-01",
    });
    try std.testing.expectEqualStrings("2024-01-01", client.getApiVersion());
}

test "CosmosClient.buildListDatabasesUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListDatabasesUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs",
        url,
    );
}

test "CosmosClient.buildDatabaseUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildDatabaseUrl(&buf, "my-db");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db",
        url,
    );
}

test "CosmosClient.buildCreateDatabaseRequest creates POST request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateDatabaseRequest(&buf, .{});
    try std.testing.expectEqual(core.http.Method.POST, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);
    try std.testing.expectEqualStrings("2018-12-31", req.getHeader("x-ms-version").?);
}

test "CosmosClient.buildGetDatabaseRequest creates GET request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildGetDatabaseRequest(&buf, "my-db");
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "CosmosClient.buildDeleteDatabaseRequest creates DELETE request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteDatabaseRequest(&buf, "my-db");
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}

test "CosmosClient.buildListContainersUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListContainersUrl(&buf, "my-db");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls",
        url,
    );
}

test "CosmosClient.buildContainerUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildContainerUrl(&buf, "my-db", "my-container");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls/my-container",
        url,
    );
}

test "CosmosClient.buildCreateContainerRequest creates POST request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateContainerRequest(&buf, "my-db", .{});
    try std.testing.expectEqual(core.http.Method.POST, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);
}

test "CosmosClient.buildGetContainerRequest creates GET request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildGetContainerRequest(&buf, "my-db", "my-container");
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "CosmosClient.buildDeleteContainerRequest creates DELETE request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteContainerRequest(&buf, "my-db", "my-container");
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}

test "CosmosClient.buildItemsUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildItemsUrl(&buf, "my-db", "my-container");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls/my-container/docs",
        url,
    );
}

test "CosmosClient.buildItemUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildItemUrl(&buf, "my-db", "my-container", "item-1");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls/my-container/docs/item-1",
        url,
    );
}

test "CosmosClient.buildCreateItemRequest creates POST request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateItemRequest(&buf, "my-db", "my-container", .{});
    try std.testing.expectEqual(core.http.Method.POST, req.method);
    try std.testing.expectEqualStrings("application/json", req.getHeader("Content-Type").?);
}

test "CosmosClient.buildCreateItemRequest with upsert sets header" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateItemRequest(&buf, "my-db", "my-container", .{
        .is_upsert = true,
    });
    try std.testing.expectEqualStrings("True", req.getHeader("x-ms-documentdb-is-upsert").?);
}

test "CosmosClient.buildCreateItemRequest with partition key sets header" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildCreateItemRequest(&buf, "my-db", "my-container", .{
        .partition_key = "[\"tenant-1\"]",
    });
    try std.testing.expectEqualStrings("[\"tenant-1\"]", req.getHeader("x-ms-documentdb-partitionkey").?);
}

test "CosmosClient.buildReadItemRequest creates GET request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildReadItemRequest(&buf, "my-db", "my-container", "item-1", .{});
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "CosmosClient.buildReadItemRequest with if_none_match" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildReadItemRequest(&buf, "my-db", "my-container", "item-1", .{
        .if_none_match = "\"etag-value\"",
    });
    try std.testing.expectEqualStrings("\"etag-value\"", req.getHeader("If-None-Match").?);
}

test "CosmosClient.buildReplaceItemRequest creates PUT request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildReplaceItemRequest(&buf, "my-db", "my-container", "item-1", .{});
    try std.testing.expectEqual(core.http.Method.PUT, req.method);
}

test "CosmosClient.buildDeleteItemRequest creates DELETE request" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteItemRequest(&buf, "my-db", "my-container", "item-1", .{});
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}

test "CosmosClient.buildQueryRequest creates POST request with query headers" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildQueryRequest(&buf, "my-db", "my-container", .{
        .query = "SELECT * FROM c",
    });
    try std.testing.expectEqual(core.http.Method.POST, req.method);
    try std.testing.expectEqualStrings("application/query+json", req.getHeader("Content-Type").?);
    try std.testing.expectEqualStrings("True", req.getHeader("x-ms-documentdb-isquery").?);
    try std.testing.expectEqualStrings("True", req.getHeader("x-ms-documentdb-query-enablecrosspartition").?);
}

test "CosmosClient.buildQueryRequest without cross-partition" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildQueryRequest(&buf, "my-db", "my-container", .{
        .query = "SELECT * FROM c",
        .enable_cross_partition = false,
    });
    try std.testing.expectEqual(@as(?[]const u8, null), req.getHeader("x-ms-documentdb-query-enablecrosspartition"));
}

test "CosmosClient.buildStoredProceduresUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildStoredProceduresUrl(&buf, "my-db", "my-container");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls/my-container/sprocs",
        url,
    );
}

test "CosmosClient.buildStoredProcedureUrl formats correctly" {
    const client = CosmosClient.init("https://my-cosmos.documents.azure.com", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildStoredProcedureUrl(&buf, "my-db", "my-container", "my-sproc");
    try std.testing.expectEqualStrings(
        "https://my-cosmos.documents.azure.com/dbs/my-db/colls/my-container/sprocs/my-sproc",
        url,
    );
}
