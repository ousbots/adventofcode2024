const std = @import("std");
const builtin = @import("builtin");

// Check for a recent version of zig.
comptime {
    const min_zig = std.SemanticVersion.parse("0.14.0") catch unreachable;
    if (builtin.zig_version.order(min_zig) == .lt) {
        @compileError(std.fmt.comptimePrint("Zig is too old {} < {}", .{ builtin.zig_version, min_zig }));
    }
}

const current_day = "src/day3.zig";

// The build graph.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create a module for our entry point.
    const day_mod = b.createModule(.{
        .root_source_file = b.path(current_day),
        .target = target,
        .optimize = optimize,
    });

    const day = b.addExecutable(.{
        .name = "adventofcode2024",
        .root_module = day_mod,
    });

    // Add a Run artifact to the build graph, executed when a dependent child step is evaluated.
    const run_cmd = b.addRunArtifact(day);

    // Pass arguments to the application from the build, like: `zig build run -- arg1 arg2 etc`.
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Add a run step. It will be visible in the `zig build --help` menu and `zig build run`.
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const day_unit_tests = b.addTest(.{
        .root_module = day_mod,
    });

    const run_unit_tests = b.addRunArtifact(day_unit_tests);

    // Add a test step to the `zig build --help` menu and `zig build test`.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
