const std = @import("std");
const days = @import("days.zig");
const util = @import("util.zig");

const usage =
    \\Usage: aoc2026 <day> [part]
    \\
    \\  day   puzzle day, 1-25
    \\  part  1 or 2 (default: run both)
    \\
    \\Examples:
    \\  zig build run -- 1
    \\  zig build run -- 1 2
    \\  zig build run -- 12 1
    \\
;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const stdout = std.Io.File.stdout();

    if (args.len < 2) {
        try stdout.writeStreamingAll(io, usage);
        return;
    }

    const day = std.fmt.parseInt(u8, args[1], 10) catch {
        try stdout.writeStreamingAll(io, usage);
        return;
    };
    if (day < 1 or day > days.count) {
        try stdout.writeStreamingAll(io, usage);
        return;
    }

    var part: ?u8 = null;
    if (args.len >= 3) {
        const parsed = std.fmt.parseInt(u8, args[2], 10) catch {
            try stdout.writeStreamingAll(io, usage);
            return;
        };
        if (parsed < 1 or parsed > 2) {
            try stdout.writeStreamingAll(io, usage);
            return;
        }
        part = parsed;
    }

    const input = util.readDayInput(io, arena, day) catch |err| {
        std.debug.print("cannot read inputs/day{d:0>2}.txt: {s}\n", .{ day, @errorName(err) });
        std.debug.print("Save your puzzle input there first (see README).\n", .{});
        std.process.exit(1);
    };

    const module: days.Day = days.modules[day - 1];

    var header_buf: [64]u8 = undefined;
    const header = try std.fmt.bufPrint(&header_buf, "--- day {d:0>2} ---\n", .{day});
    try stdout.writeStreamingAll(io, header);

    if (part == null or part == 1) try runPart(io, stdout, arena, module, 1, input);
    if (part == null or part == 2) try runPart(io, stdout, arena, module, 2, input);
}

fn solve(allocator: std.mem.Allocator, module: days.Day, part: u8, input: []const u8) !i64 {
    return switch (part) {
        1 => module.part1(allocator, input),
        2 => module.part2(allocator, input),
        else => unreachable,
    };
}

fn runPart(
    io: std.Io,
    stdout: std.Io.File,
    allocator: std.mem.Allocator,
    module: days.Day,
    part: u8,
    input: []const u8,
) !void {
    var buf: [256]u8 = undefined;

    const start = std.Io.Clock.Timestamp.now(io, .awake);
    const result = solve(allocator, module, part, input) catch |err| {
        const msg = try std.fmt.bufPrint(&buf, "part {d}: error.{s}\n", .{ part, @errorName(err) });
        try stdout.writeStreamingAll(io, msg);
        return;
    };
    const elapsed_ns = start.untilNow(io).raw.toNanoseconds();
    const elapsed_ms: f64 = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_ms;

    const msg = try std.fmt.bufPrint(&buf, "part {d}: {d}  ({d:.2} ms)\n", .{ part, result, elapsed_ms });
    try stdout.writeStreamingAll(io, msg);
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("days.zig");
    _ = @import("util.zig");
}
