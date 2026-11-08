const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/3

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    return solve(input, 2);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    return solve(input, 12);
}

fn solve(input: []const u8, batteries: usize) !i64 {
    var total: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        total += bestJoltage(line, batteries);
    }
    return total;
}

/// Picks `count` digits in order, always taking the largest digit that still
/// leaves enough characters for the remaining picks.
fn bestJoltage(line: []const u8, count: usize) i64 {
    var value: i64 = 0;
    var start: usize = 0;
    var remaining = count;

    while (remaining > 0) : (remaining -= 1) {
        const last = line.len - remaining;
        var best = start;
        var i = start + 1;
        while (i <= last) : (i += 1) {
            if (line[i] > line[best]) best = i;
        }

        value = value * 10 + @as(i64, line[best] - '0');
        start = best + 1;
    }
    return value;
}

const sample =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 357), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 3121910778619), try part2(std.testing.allocator, sample));
}
