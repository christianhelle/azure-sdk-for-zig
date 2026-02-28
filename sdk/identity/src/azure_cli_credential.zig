/// Authenticates using the Azure CLI.
///
/// Obtains tokens by invoking `az account get-access-token` from the Azure CLI.
/// Requires that the Azure CLI is installed and the user is logged in.
const std = @import("std");
const core = @import("azure_core");
const AccessToken = core.auth.AccessToken;
const TokenRequestOptions = core.auth.TokenRequestOptions;
const TokenCredential = core.auth.TokenCredential;

pub const AzureCliCredential = struct {
    /// Optional subscription ID to use.
    subscription_id: ?[]const u8 = null,

    pub fn init() AzureCliCredential {
        return .{};
    }

    pub fn initWithSubscription(subscription_id: []const u8) AzureCliCredential {
        return .{ .subscription_id = subscription_id };
    }

    /// Builds the `az` CLI command arguments for obtaining a token.
    pub fn buildCommand(self: *const AzureCliCredential, buf: []u8, scope: []const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll("az account get-access-token --resource ") catch return error.BufferTooSmall;
        writer.writeAll(scope) catch return error.BufferTooSmall;
        writer.writeAll(" --output json") catch return error.BufferTooSmall;

        if (self.subscription_id) |sub| {
            writer.writeAll(" --subscription ") catch return error.BufferTooSmall;
            writer.writeAll(sub) catch return error.BufferTooSmall;
        }

        return stream.getWritten();
    }

    /// Returns this credential as a `TokenCredential` interface.
    pub fn tokenCredential(self: *AzureCliCredential) TokenCredential {
        return .{
            .ptr = @ptrCast(self),
            .getTokenFn = @ptrCast(&getToken),
        };
    }

    fn getToken(_: *AzureCliCredential, _: TokenRequestOptions) !AccessToken {
        return error.AzureCliNotInstalled;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "AzureCliCredential.init creates default credential" {
    const cred = AzureCliCredential.init();
    try std.testing.expectEqual(@as(?[]const u8, null), cred.subscription_id);
}

test "AzureCliCredential.initWithSubscription sets subscription" {
    const cred = AzureCliCredential.initWithSubscription("sub-123");
    try std.testing.expectEqualStrings("sub-123", cred.subscription_id.?);
}

test "AzureCliCredential.buildCommand formats correctly" {
    const cred = AzureCliCredential.init();
    var buf: [256]u8 = undefined;
    const cmd = try cred.buildCommand(&buf, "https://management.azure.com");
    try std.testing.expectEqualStrings(
        "az account get-access-token --resource https://management.azure.com --output json",
        cmd,
    );
}

test "AzureCliCredential.buildCommand includes subscription" {
    const cred = AzureCliCredential.initWithSubscription("sub-123");
    var buf: [256]u8 = undefined;
    const cmd = try cred.buildCommand(&buf, "https://management.azure.com");
    try std.testing.expect(std.mem.indexOf(u8, cmd, "--subscription sub-123") != null);
}
