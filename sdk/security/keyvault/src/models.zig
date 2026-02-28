/// Azure Key Vault data models.
///
/// Defines types for Key Vault secrets, keys, and certificates.
const std = @import("std");

// ── Secrets ─────────────────────────────────────────────────────

/// Attributes common to Key Vault objects.
pub const Attributes = struct {
    enabled: bool = true,
    /// Not-before date as Unix timestamp.
    not_before: ?i64 = null,
    /// Expiration date as Unix timestamp.
    expires: ?i64 = null,
    /// Creation time as Unix timestamp (read-only, set by service).
    created: ?i64 = null,
    /// Last updated time as Unix timestamp (read-only, set by service).
    updated: ?i64 = null,
};

/// Properties of a Key Vault secret.
pub const SecretProperties = struct {
    id: ?[]const u8 = null,
    name: []const u8,
    vault_url: ?[]const u8 = null,
    version: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    attributes: Attributes = .{},
    tags_keys: [max_tags][]const u8 = undefined,
    tags_values: [max_tags][]const u8 = undefined,
    tag_count: usize = 0,

    const max_tags = 16;

    pub fn addTag(self: *SecretProperties, key: []const u8, value: []const u8) !void {
        if (self.tag_count >= max_tags) return error.TooManyTags;
        self.tags_keys[self.tag_count] = key;
        self.tags_values[self.tag_count] = value;
        self.tag_count += 1;
    }

    pub fn getTag(self: *const SecretProperties, key: []const u8) ?[]const u8 {
        for (0..self.tag_count) |i| {
            if (std.mem.eql(u8, self.tags_keys[i], key)) {
                return self.tags_values[i];
            }
        }
        return null;
    }
};

/// A Key Vault secret (value + properties).
pub const Secret = struct {
    value: ?[]const u8 = null,
    properties: SecretProperties,
};

/// Options for listing secrets.
pub const ListSecretsOptions = struct {
    max_results: ?u32 = null,
};

/// Options for setting a secret.
pub const SetSecretOptions = struct {
    content_type: ?[]const u8 = null,
    enabled: bool = true,
    not_before: ?i64 = null,
    expires: ?i64 = null,
};

// ── Keys ────────────────────────────────────────────────────────

/// Key types supported by Key Vault.
pub const KeyType = enum {
    rsa,
    rsa_hsm,
    ec,
    ec_hsm,
    oct,
    oct_hsm,

    pub fn toString(self: KeyType) []const u8 {
        return switch (self) {
            .rsa => "RSA",
            .rsa_hsm => "RSA-HSM",
            .ec => "EC",
            .ec_hsm => "EC-HSM",
            .oct => "oct",
            .oct_hsm => "oct-HSM",
        };
    }
};

/// Key operations permitted with this key.
pub const KeyOperation = enum {
    encrypt,
    decrypt,
    sign,
    verify,
    wrap_key,
    unwrap_key,

    pub fn toString(self: KeyOperation) []const u8 {
        return switch (self) {
            .encrypt => "encrypt",
            .decrypt => "decrypt",
            .sign => "sign",
            .verify => "verify",
            .wrap_key => "wrapKey",
            .unwrap_key => "unwrapKey",
        };
    }
};

/// Properties of a Key Vault key.
pub const KeyProperties = struct {
    id: ?[]const u8 = null,
    name: []const u8,
    vault_url: ?[]const u8 = null,
    version: ?[]const u8 = null,
    key_type: KeyType = .rsa,
    attributes: Attributes = .{},
};

/// Options for creating a key.
pub const CreateKeyOptions = struct {
    key_type: KeyType = .rsa,
    key_size: ?u32 = null,
    enabled: bool = true,
};

// ── Certificates ────────────────────────────────────────────────

/// Certificate content type.
pub const CertificateContentType = enum {
    pkcs12,
    pem,

    pub fn toString(self: CertificateContentType) []const u8 {
        return switch (self) {
            .pkcs12 => "application/x-pkcs12",
            .pem => "application/x-pem-file",
        };
    }
};

/// Properties of a Key Vault certificate.
pub const CertificateProperties = struct {
    id: ?[]const u8 = null,
    name: []const u8,
    vault_url: ?[]const u8 = null,
    version: ?[]const u8 = null,
    attributes: Attributes = .{},
};

// ── Tests ────────────────────────────────────────────────────────
test "SecretProperties.addTag and getTag work correctly" {
    var props = SecretProperties{ .name = "test-secret" };
    try props.addTag("env", "production");
    try std.testing.expectEqualStrings("production", props.getTag("env").?);
    try std.testing.expectEqual(@as(?[]const u8, null), props.getTag("missing"));
}

test "Attributes has sensible defaults" {
    const attrs = Attributes{};
    try std.testing.expect(attrs.enabled);
    try std.testing.expectEqual(@as(?i64, null), attrs.not_before);
    try std.testing.expectEqual(@as(?i64, null), attrs.expires);
}

test "Secret can be constructed" {
    const secret = Secret{
        .value = "my-secret-value",
        .properties = .{ .name = "my-secret" },
    };
    try std.testing.expectEqualStrings("my-secret-value", secret.value.?);
    try std.testing.expectEqualStrings("my-secret", secret.properties.name);
}

test "KeyType.toString returns correct strings" {
    try std.testing.expectEqualStrings("RSA", KeyType.rsa.toString());
    try std.testing.expectEqualStrings("RSA-HSM", KeyType.rsa_hsm.toString());
    try std.testing.expectEqualStrings("EC", KeyType.ec.toString());
    try std.testing.expectEqualStrings("EC-HSM", KeyType.ec_hsm.toString());
    try std.testing.expectEqualStrings("oct", KeyType.oct.toString());
    try std.testing.expectEqualStrings("oct-HSM", KeyType.oct_hsm.toString());
}

test "KeyOperation.toString returns correct strings" {
    try std.testing.expectEqualStrings("encrypt", KeyOperation.encrypt.toString());
    try std.testing.expectEqualStrings("decrypt", KeyOperation.decrypt.toString());
    try std.testing.expectEqualStrings("sign", KeyOperation.sign.toString());
    try std.testing.expectEqualStrings("verify", KeyOperation.verify.toString());
    try std.testing.expectEqualStrings("wrapKey", KeyOperation.wrap_key.toString());
    try std.testing.expectEqualStrings("unwrapKey", KeyOperation.unwrap_key.toString());
}

test "CertificateContentType.toString returns correct strings" {
    try std.testing.expectEqualStrings("application/x-pkcs12", CertificateContentType.pkcs12.toString());
    try std.testing.expectEqualStrings("application/x-pem-file", CertificateContentType.pem.toString());
}

test "KeyProperties has sensible defaults" {
    const props = KeyProperties{ .name = "my-key" };
    try std.testing.expectEqual(KeyType.rsa, props.key_type);
    try std.testing.expect(props.attributes.enabled);
}

test "CreateKeyOptions defaults" {
    const opts = CreateKeyOptions{};
    try std.testing.expectEqual(KeyType.rsa, opts.key_type);
    try std.testing.expectEqual(@as(?u32, null), opts.key_size);
    try std.testing.expect(opts.enabled);
}

test "SetSecretOptions defaults" {
    const opts = SetSecretOptions{};
    try std.testing.expect(opts.enabled);
    try std.testing.expectEqual(@as(?[]const u8, null), opts.content_type);
}

test "ListSecretsOptions defaults" {
    const opts = ListSecretsOptions{};
    try std.testing.expectEqual(@as(?u32, null), opts.max_results);
}

test "CertificateProperties can be constructed" {
    const props = CertificateProperties{ .name = "my-cert" };
    try std.testing.expectEqualStrings("my-cert", props.name);
    try std.testing.expect(props.attributes.enabled);
}
