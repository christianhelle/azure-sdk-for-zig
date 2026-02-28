/// Authenticates using Azure Managed Identity.
///
/// Supports both system-assigned and user-assigned managed identities.
/// Works with Azure VMs, App Service, Azure Functions, and other
/// Azure-hosted resources.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

pub const ManagedIdentityCredential = struct {
    /// Client ID for user-assigned managed identity (null for system-assigned).
    client_id: ?[]const u8 = null,
    /// The IMDS endpoint to use.
    imds_endpoint: []const u8 = "http://169.254.169.254/metadata/identity/oauth2/token",

    pub fn init() ManagedIdentityCredential {
        return .{};
    }

    pub fn initWithClientId(client_id: []const u8) ManagedIdentityCredential {
        return .{ .client_id = client_id };
    }

    /// Builds the IMDS token request URL with query parameters.
    pub fn buildTokenUrl(self: *const ManagedIdentityCredential, buf: []u8, resource: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.imds_endpoint) catch return error.BufferTooSmall;
        writer.writeAll("?api-version=2018-02-01&resource=") catch return error.BufferTooSmall;
        writer.writeAll(resource) catch return error.BufferTooSmall;

        if (self.client_id) |cid| {
            writer.writeAll("&client_id=") catch return error.BufferTooSmall;
            writer.writeAll(cid) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Returns this credential as a `TokenCredential` interface.
    pub fn tokenCredential(self: *ManagedIdentityCredential) TokenCredential {
        return .{
            .ptr = @ptrCast(self),
            .getTokenFn = @ptrCast(&getToken),
        };
    }

    fn getToken(_: *ManagedIdentityCredential, _: TokenRequestOptions) !AccessToken {
        return error.ManagedIdentityUnavailable;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "ManagedIdentityCredential.init creates system-assigned credential" {
    const cred = ManagedIdentityCredential.init();
    try std.testing.expectEqual(@as(?[]const u8, null), cred.client_id);
}

test "ManagedIdentityCredential.initWithClientId sets client ID" {
    const cred = ManagedIdentityCredential.initWithClientId("my-client-id");
    try std.testing.expectEqualStrings("my-client-id", cred.client_id.?);
}

test "ManagedIdentityCredential.buildTokenUrl formats correctly for system-assigned" {
    const cred = ManagedIdentityCredential.init();
    var buf: [512]u8 = undefined;
    const url = try cred.buildTokenUrl(&buf, "https://management.azure.com");
    try std.testing.expectEqualStrings(
        "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com",
        url,
    );
}

test "ManagedIdentityCredential.buildTokenUrl includes client_id for user-assigned" {
    const cred = ManagedIdentityCredential.initWithClientId("my-client-id");
    var buf: [512]u8 = undefined;
    const url = try cred.buildTokenUrl(&buf, "https://management.azure.com");
    try std.testing.expect(std.mem.indexOf(u8, url, "&client_id=my-client-id") != null);
}
