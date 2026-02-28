/// Azure Key Vault Certificate client.
///
/// Provides operations for managing certificates in Azure Key Vault:
/// - Get, create, import, and delete certificates
/// - List certificates and certificate versions
/// - Certificate policy management
const std = @import("std");
const core = @import("azure_core");

pub const CertificateClient = struct {
    vault_url: []const u8,
    options: core.ClientOptions,

    const api_version = "7.5";

    pub fn init(vault_url: []const u8, options: ?core.ClientOptions) CertificateClient {
        return .{
            .vault_url = vault_url,
            .options = options orelse core.ClientOptions.default,
        };
    }

    pub fn getApiVersion(self: *const CertificateClient) []const u8 {
        return self.options.api_version orelse api_version;
    }

    /// Builds the URL for a specific certificate.
    pub fn buildCertificateUrl(self: *const CertificateClient, buf: []u8, cert_name: []const u8, version: ?[]const u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/certificates/") catch return error.BufferTooSmall;
        writer.writeAll(cert_name) catch return error.BufferTooSmall;

        if (version) |v| {
            writer.writeByte('/') catch return error.BufferTooSmall;
            writer.writeAll(v) catch return error.BufferTooSmall;
        }

        writer.writeAll("?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the URL for listing certificates.
    pub fn buildListCertificatesUrl(self: *const CertificateClient, buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(buf);
        const writer = stream.writer();

        writer.writeAll(self.vault_url) catch return error.BufferTooSmall;
        writer.writeAll("/certificates?api-version=") catch return error.BufferTooSmall;
        writer.writeAll(self.getApiVersion()) catch return error.BufferTooSmall;

        return stream.getWritten();
    }

    /// Builds the request for getting a certificate.
    pub fn buildGetCertificateRequest(self: *const CertificateClient, buf: []u8, cert_name: []const u8, version: ?[]const u8) !core.http.Request {
        const url = try self.buildCertificateUrl(buf, cert_name, version);
        var req = core.http.Request.init(.GET, url);
        try req.setHeader("Accept", "application/json");
        return req;
    }

    /// Builds the request for deleting a certificate.
    pub fn buildDeleteCertificateRequest(self: *const CertificateClient, buf: []u8, cert_name: []const u8) !core.http.Request {
        const url = try self.buildCertificateUrl(buf, cert_name, null);
        var req = core.http.Request.init(.DELETE, url);
        try req.setHeader("Accept", "application/json");
        return req;
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "CertificateClient.init creates client" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    try std.testing.expectEqualStrings("https://my-vault.vault.azure.net", client.vault_url);
}

test "CertificateClient.buildCertificateUrl formats correctly" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildCertificateUrl(&buf, "my-cert", null);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/certificates/my-cert?api-version=7.5",
        url,
    );
}

test "CertificateClient.buildCertificateUrl with version" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildCertificateUrl(&buf, "my-cert", "v1");
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/certificates/my-cert/v1?api-version=7.5",
        url,
    );
}

test "CertificateClient.buildListCertificatesUrl formats correctly" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const url = try client.buildListCertificatesUrl(&buf);
    try std.testing.expectEqualStrings(
        "https://my-vault.vault.azure.net/certificates?api-version=7.5",
        url,
    );
}

test "CertificateClient.buildGetCertificateRequest creates GET request" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildGetCertificateRequest(&buf, "my-cert", null);
    try std.testing.expectEqual(core.http.Method.GET, req.method);
}

test "CertificateClient.buildDeleteCertificateRequest creates DELETE request" {
    const client = CertificateClient.init("https://my-vault.vault.azure.net", null);
    var buf: [256]u8 = undefined;
    const req = try client.buildDeleteCertificateRequest(&buf, "my-cert");
    try std.testing.expectEqual(core.http.Method.DELETE, req.method);
}
