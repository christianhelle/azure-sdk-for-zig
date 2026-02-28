const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Azure Core ──────────────────────────────────────────────
    const core_mod = b.addModule("azure_core", .{
        .root_source_file = b.path("sdk/core/src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── Azure Identity ──────────────────────────────────────────
    const identity_mod = b.addModule("azure_identity", .{
        .root_source_file = b.path("sdk/identity/src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "azure_core", .module = core_mod },
        },
    });
    _ = identity_mod;

    // ── Azure Storage Blob ──────────────────────────────────────
    const storage_blob_mod = b.addModule("azure_storage_blob", .{
        .root_source_file = b.path("sdk/storage/blob/src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "azure_core", .module = core_mod },
        },
    });
    _ = storage_blob_mod;

    // ── Tests ───────────────────────────────────────────────────
    const test_step = b.step("test", "Run all unit tests");

    // Core tests
    const core_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("sdk/core/src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_core_tests = b.addRunArtifact(core_tests);
    test_step.dependOn(&run_core_tests.step);

    // Identity tests
    const identity_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("sdk/identity/src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "azure_core", .module = core_mod },
            },
        }),
    });
    const run_identity_tests = b.addRunArtifact(identity_tests);
    test_step.dependOn(&run_identity_tests.step);

    // Storage Blob tests
    const storage_blob_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("sdk/storage/blob/src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "azure_core", .module = core_mod },
            },
        }),
    });
    const run_storage_blob_tests = b.addRunArtifact(storage_blob_tests);
    test_step.dependOn(&run_storage_blob_tests.step);
}
