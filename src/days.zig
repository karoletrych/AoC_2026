const std = @import("std");

/// Number of days scaffolded in this repository.
pub const count = 25;

/// Signature every day module must implement.
pub const SolveFn = *const fn (allocator: std.mem.Allocator, input: []const u8) anyerror!i64;

pub const Day = struct {
    part1: SolveFn,
    part2: SolveFn,
};

/// Day modules, in puzzle order.
pub const types = [_]type{
    @import("days/day01.zig"),
    @import("days/day02.zig"),
    @import("days/day03.zig"),
    @import("days/day04.zig"),
    @import("days/day05.zig"),
    @import("days/day06.zig"),
    @import("days/day07.zig"),
    @import("days/day08.zig"),
    @import("days/day09.zig"),
    @import("days/day10.zig"),
    @import("days/day11.zig"),
    @import("days/day12.zig"),
    @import("days/day13.zig"),
    @import("days/day14.zig"),
    @import("days/day15.zig"),
    @import("days/day16.zig"),
    @import("days/day17.zig"),
    @import("days/day18.zig"),
    @import("days/day19.zig"),
    @import("days/day20.zig"),
    @import("days/day21.zig"),
    @import("days/day22.zig"),
    @import("days/day23.zig"),
    @import("days/day24.zig"),
    @import("days/day25.zig"),
};

/// Runtime-callable registry built from `types`.
pub const modules = blk: {
    var days: [count]Day = undefined;
    for (types, 0..) |DayType, i| {
        days[i] = .{
            .part1 = DayType.part1,
            .part2 = DayType.part2,
        };
    }
    break :blk days;
};

test "every day module exposes part1 and part2" {
    inline for (types) |DayType| {
        std.testing.refAllDecls(DayType);
    }
}
