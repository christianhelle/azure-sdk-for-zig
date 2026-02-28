/// Authenticates as a service principal using a client ID and client secret.
///
/// This credential is suitable for server-to-server authentication scenarios
/// where a client secret has been registered with Azure AD.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;
const Cloud = core.Cloud;

pub const ClientSecretCredential = struct {
    tenant_id: []const u8,
    client_id: []const u8,
    client_secret: []const u8,
    cloud: Cloud = Cloud.azure_public,
    cached_token: ?AccessToken = null,

    pub fn init(tenant_id: []const u8, client_id: []const u8, client_secret: []const u8) ClientSecretCredential {
        return .{
            .tenant_id = tenant_id,
            .client_id = client_id,
            .client_secret = client_secret,
        };
    }

    pub fn initWithCloud(tenant_id: []const u8, client_id: []const u8, client_secret: []const u8, cloud: Cloud) ClientSecretCredential {
        return .{
            .tenant_id = tenant_id,
            .client_id = client_id,
            .client_secret = client_secret,
            .cloud = cloud,
        };
    }

    /// Builds the token endpoint URL for this credential's tenant.
    pub fn getTokenEndpoint(self: *const ClientSecretCredential, buf: []u8) ![]const u8 {
        return self.cloud.getTokenEndpoint(buf, self.tenant_id);
    }

    /// Builds the x-www-form-urlencoded request body for the token request.
    pub fn buildRequestBody(self: *const ClientSecretCredential, buf: []u8, scopes: []const []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll("grant_type=client_credentials&client_id=") catch return error.BufferTooSmall;
        writer.writeAll(self.client_id) catch return error.BufferTooSmall;
        writer.writeAll("&client_secret=") catch return error.BufferTooSmall;
        writer.writeAll(self.client_secret) catch return error.BufferTooSmall;
        writer.writeAll("&scope=") catch return error.BufferTooSmall;

        for (scopes, 0..) |scope, i| {
            if (i > 0) writer.writeByte(' ') catch return error.BufferTooSmall;
            writer.writeAll(scope) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Returns this credential as a `TokenCredential` interface.
    pub fn tokenCredential(self: *ClientSecretCredential) TokenCredential {
        return .{
            .ptr = @ptrCast(self),
            .getTokenFn = @ptrCast(&getToken),
        };
    }

    fn getToken(_: *ClientSecretCredential, _: TokenRequestOptions) !AccessToken {
        // In a real implementation, this would make an HTTP POST to the token endpoint.
        // For now, return an error indicating that a real HTTP client is needed.
        return error.HttpClientRequired;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ClientSecretCredential.init sets fields correctly" {
    const cred = ClientSecretCredential.init("tenant", "client", "secret");
    try std.testing.expectEqualStrings("tenant", cred.tenant_id);
    try std.testing.expectEqualStrings("client", cred.client_id);
    try std.testing.expectEqualStrings("secret", cred.client_secret);
}

test "ClientSecretCredential uses public cloud by default" {
    const cred = ClientSecretCredential.init("tenant", "client", "secret");
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com",
        cred.cloud.active_directory_authority_url,
    );
}

test "ClientSecretCredential.initWithCloud uses specified cloud" {
    const cred = ClientSecretCredential.initWithCloud("tenant", "client", "secret", Cloud.azure_china);
    try std.testing.expectEqualStrings(
        "https://login.chinacloudapi.cn",
        cred.cloud.active_directory_authority_url,
    );
}

test "ClientSecretCredential.getTokenEndpoint builds correct URL" {
    const cred = ClientSecretCredential.init("my-tenant", "client", "secret");
    var buf: [256]u8 = undefined;
    const url = try cred.getTokenEndpoint(&buf);
    try std.testing.expectEqualStrings(
        "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token",
        url,
    );
}

test "ClientSecretCredential.buildRequestBody formats correctly" {
    const cred = ClientSecretCredential.init("tenant", "my-client-id", "my-secret");
    var buf: [512]u8 = undefined;
    const scopes = [_][]const u8{"https://management.azure.com/.default"};
    const body = try cred.buildRequestBody(&buf, &scopes);
    try std.testing.expectEqualStrings(
        "grant_type=client_credentials&client_id=my-client-id&client_secret=my-secret&scope=https://management.azure.com/.default",
        body,
    );
}

test "ClientSecretCredential.buildRequestBody handles multiple scopes" {
    const cred = ClientSecretCredential.init("tenant", "client", "secret");
    var buf: [512]u8 = undefined;
    const scopes = [_][]const u8{ "scope1", "scope2" };
    const body = try cred.buildRequestBody(&buf, &scopes);
    try std.testing.expect(std.mem.indexOf(u8, body, "scope=scope1 scope2") != null);
}

test "ClientSecretCredential.tokenCredential returns interface" {
    var cred = ClientSecretCredential.init("tenant", "client", "secret");
    const tc = cred.tokenCredential();
    // Verify the interface pointers are non-null by checking they point to cred
    try std.testing.expect(@intFromPtr(tc.ptr) == @intFromPtr(&cred));
}
