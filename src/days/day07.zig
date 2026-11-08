const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/7

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try util.fromLines(allocator, input);
    defer grid.deinit();

    const start = grid.find('S') orelse return error.NoStart;
    const width = grid.width;

    var active = try allocator.alloc(bool, width);
    defer allocator.free(active);
    var next = try allocator.alloc(bool, width);
    defer allocator.free(next);
    @memset(active, false);
    @memset(next, false);
    active[start.x] = true;

    var splits: i64 = 0;
    var y = start.y + 1;
    while (y < grid.height) : (y += 1) {
        @memset(next, false);
        for (0..width) |x| {
            if (!active[x]) continue;
            if (grid.at(x, y) == '^') {
                splits += 1;
                if (x > 0) next[x - 1] = true;
                if (x + 1 < width) next[x + 1] = true;
            } else {
                next[x] = true;
            }
        }
        const swap = active;
        active = next;
        next = swap;
    }
    return splits;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try util.fromLines(allocator, input);
    defer grid.deinit();

    const start = grid.find('S') orelse return error.NoStart;
    const width = grid.width;

    var below = try allocator.alloc(i64, width);
    defer allocator.free(below);
    var current = try allocator.alloc(i64, width);
    defer allocator.free(current);
    @memset(below, 1); // paths that exit below the last row

    var answer: i64 = 0;
    var y = grid.height;
    while (y > 0) {
        y -= 1;
        for (0..width) |x| {
            if (grid.at(x, y) == '^') {
                const left: i64 = if (y + 1 >= grid.height) 1 else if (x > 0) below[x - 1] else 0;
                const right: i64 = if (y + 1 >= grid.height) 1 else if (x + 1 < width) below[x + 1] else 0;
                current[x] = left + right;
            } else {
                current[x] = if (y + 1 >= grid.height) 1 else below[x];
            }
        }
        if (y == start.y) {
            answer = current[start.x];
            break;
        }
        const swap = below;
        below = current;
        current = swap;
    }
    return answer;
}

const sample =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 21), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 40), try part2(std.testing.allocator, sample));
}
