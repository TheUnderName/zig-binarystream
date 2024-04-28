const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "binary",

        .root_source_file = .{ .path = "binary.zig" },

        .target = target,

        .optimize = optimize,
    });

    b.reference_trace = 10;

    b.installArtifact(exe);
}
