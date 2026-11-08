const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/1

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var position: i64 = 50;
    var zeros: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const amount = try std.fmt.parseInt(i64, line[1..], 10);
        const direction: i64 = if (line[0] == 'L') -1 else 1;

        position = @mod(position + direction * amount, 100);
        if (position == 0) zeros += 1;
    }
    return zeros;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var position: i64 = 50;
    var zeros: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const amount = try std.fmt.parseInt(i64, line[1..], 10);
        const direction: i64 = if (line[0] == 'L') -1 else 1;

        var step: i64 = 0;
        while (step < amount) : (step += 1) {
            position = @mod(position + direction, 100);
            if (position == 0) zeros += 1;
        }
    }
    return zeros;
}

const sample =
    \\L68
    \\L30
    \\R48
    \\L5
    \\R60
    \\L55
    \\L1
    \\L99
    \\R14
    \\L82
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 3), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 6), try part2(std.testing.allocator, sample));
}
