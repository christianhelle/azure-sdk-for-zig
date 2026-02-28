/// Azure cloud environment configuration.
///
/// Defines the endpoints for different Azure cloud environments
/// (Public, China, US Government, and custom clouds).
pub const Cloud = struct {
    /// The base URL for Azure Active Directory (Entra ID) authentication.
    active_directory_authority_url: []const u8,
    /// The default authentication scope for the cloud environment.
    default_scope: []const u8,
    /// The Azure Resource Manager endpoint.
    resource_manager_url: []const u8,
    /// The Azure portal URL.
    portal_url: []const u8,

    /// Azure Public Cloud (default).
    pub const azure_public = Cloud{
        .active_directory_authority_url = "https://login.microsoftonline.com",
        .default_scope = "https://management.azure.com/.default",
        .resource_manager_url = "https://management.azure.com",
        .portal_url = "https://portal.azure.com",
    };

    /// Azure China Cloud (21Vianet).
    pub const azure_china = Cloud{
        .active_directory_authority_url = "https://login.chinacloudapi.cn",
        .default_scope = "https://management.chinacloudapi.cn/.default",
        .resource_manager_url = "https://management.chinacloudapi.cn",
        .portal_url = "https://portal.azure.cn",
    };

    /// Azure US Government Cloud.
    pub const azure_government = Cloud{
        .active_directory_authority_url = "https://login.microsoftonline.us",
        .default_scope = "https://management.usgovcloudapi.net/.default",
        .resource_manager_url = "https://management.usgovcloudapi.net",
        .portal_url = "https://portal.azure.us",
    };

    /// Returns the token endpoint URL for a given tenant.
    pub fn getTokenEndpoint(self: Cloud, buf: []u8, tenant_id: []const u8) ![]const u8 {
        const written = std.fmt.bufPrint(buf, "{s}/{s}/oauth2/v2.0/token", .{
            self.active_directory_authority_url,
            tenant_id,
        }) catch return error.BufferTooSmall;
        return written;
    }

    /// Returns the authorize endpoint URL for a given tenant.
    pub fn getAuthorizeEndpoint(self: Cloud, buf: []u8, tenant_id: []const u8) ![]const u8 {
        const written = std.fmt.bufPrint(buf, "{s}/{s}/oauth2/v2.0/authorize", .{
            self.active_directory_authority_url,
            tenant_id,
        }) catch return error.BufferTooSmall;
        return written;
    }
};

const std = @import("std");

// ── Tests ────────────────────────────────────────────────────────
test "azure_public has correct authority URL" {
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com",
        Cloud.azure_public.active_directory_authority_url,
    );
}

test "azure_china has correct authority URL" {
    try std.testing.expectEqualStrings(
        "https://login.chinacloudapi.cn",
        Cloud.azure_china.active_directory_authority_url,
    );
}

test "azure_government has correct authority URL" {
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.us",
        Cloud.azure_government.active_directory_authority_url,
    );
}

test "getTokenEndpoint formats correctly" {
    var buf: [256]u8 = undefined;
    const url = try Cloud.azure_public.getTokenEndpoint(&buf, "my-tenant-id");
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com/my-tenant-id/oauth2/v2.0/token",
        url,
    );
}

test "getAuthorizeEndpoint formats correctly" {
    var buf: [256]u8 = undefined;
    const url = try Cloud.azure_public.getAuthorizeEndpoint(&buf, "my-tenant-id");
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com/my-tenant-id/oauth2/v2.0/authorize",
        url,
    );
}

test "getTokenEndpoint with small buffer returns error" {
    var buf: [10]u8 = undefined;
    const result = Cloud.azure_public.getTokenEndpoint(&buf, "my-tenant-id");
    try std.testing.expectError(error.BufferTooSmall, result);
}

test "all clouds have non-empty fields" {
    const clouds = [_]Cloud{
        Cloud.azure_public,
        Cloud.azure_china,
        Cloud.azure_government,
    };
    for (clouds) |cloud| {
        try std.testing.expect(cloud.active_directory_authority_url.len > 0);
        try std.testing.expect(cloud.default_scope.len > 0);
        try std.testing.expect(cloud.resource_manager_url.len > 0);
        try std.testing.expect(cloud.portal_url.len > 0);
    }
}
