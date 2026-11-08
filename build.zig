const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "aoc2026",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run a day: zig build run -- <day> [part]");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const pull_exe = b.addExecutable(.{
        .name = "aoc2026-pull",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/pull.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const pull_step = b.step("pull", "Download a puzzle input: zig build pull -- <day> [year]");
    const pull_cmd = b.addRunArtifact(pull_exe);
    pull_cmd.addPassthruArgs();
    pull_step.dependOn(&pull_cmd.step);
}
