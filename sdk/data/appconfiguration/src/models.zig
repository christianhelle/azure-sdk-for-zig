/// Azure App Configuration data models.
///
/// Defines types for configuration settings and feature flags.
const std = @import("std");

/// A configuration setting in Azure App Configuration.
pub const ConfigurationSetting = struct {
    key: []const u8,
    value: ?[]const u8 = null,
    label: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    etag: ?[]const u8 = null,
    last_modified: ?[]const u8 = null,
    locked: bool = false,
};

/// Options for listing configuration settings.
pub const ListSettingsOptions = struct {
    key_filter: ?[]const u8 = null,
    label_filter: ?[]const u8 = null,
};

/// Options for setting a configuration value.
pub const SetSettingOptions = struct {
    label: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    if_match: ?[]const u8 = null,
};

/// A feature flag in Azure App Configuration.
pub const FeatureFlag = struct {
    id: []const u8,
    enabled: bool = false,
    description: ?[]const u8 = null,
};

// ── Tests ────────────────────────────────────────────────────────
test "ConfigurationSetting can be constructed" {
    const setting = ConfigurationSetting{
        .key = "app:color",
        .value = "blue",
        .label = "production",
    };
    try std.testing.expectEqualStrings("app:color", setting.key);
    try std.testing.expectEqualStrings("blue", setting.value.?);
    try std.testing.expectEqualStrings("production", setting.label.?);
    try std.testing.expect(!setting.locked);
}

test "ConfigurationSetting defaults" {
    const setting = ConfigurationSetting{ .key = "test" };
    try std.testing.expectEqual(@as(?[]const u8, null), setting.value);
    try std.testing.expectEqual(@as(?[]const u8, null), setting.label);
    try std.testing.expect(!setting.locked);
}

test "ListSettingsOptions defaults" {
    const opts = ListSettingsOptions{};
    try std.testing.expectEqual(@as(?[]const u8, null), opts.key_filter);
    try std.testing.expectEqual(@as(?[]const u8, null), opts.label_filter);
}

test "FeatureFlag can be constructed" {
    const flag = FeatureFlag{
        .id = "beta-feature",
        .enabled = true,
        .description = "A new beta feature",
    };
    try std.testing.expectEqualStrings("beta-feature", flag.id);
    try std.testing.expect(flag.enabled);
}

test "FeatureFlag defaults" {
    const flag = FeatureFlag{ .id = "test" };
    try std.testing.expect(!flag.enabled);
    try std.testing.expectEqual(@as(?[]const u8, null), flag.description);
}
