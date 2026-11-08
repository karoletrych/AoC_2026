const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/4

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try util.fromLines(allocator, input);
    defer grid.deinit();

    var count: i64 = 0;
    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            if (grid.at(x, y) == '@' and rollsAround(grid, x, y) < 4) count += 1;
        }
    }
    return count;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try util.fromLines(allocator, input);
    defer grid.deinit();

    var removed: i64 = 0;
    while (true) {
        var removable: std.ArrayList(util.Point) = .empty;
        defer removable.deinit(allocator);

        for (0..grid.height) |y| {
            for (0..grid.width) |x| {
                if (grid.at(x, y) == '@' and rollsAround(grid, x, y) < 4) {
                    try removable.append(allocator, .{ .x = x, .y = y });
                }
            }
        }

        if (removable.items.len == 0) break;
        for (removable.items) |point| grid.set(point.x, point.y, '.');
        removed += @intCast(removable.items.len);
    }
    return removed;
}

fn rollsAround(grid: util.Grid(u8), x: usize, y: usize) usize {
    var count: usize = 0;
    const xi: isize = @intCast(x);
    const yi: isize = @intCast(y);

    var dy: isize = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: isize = -1;
        while (dx <= 1) : (dx += 1) {
            if (dx == 0 and dy == 0) continue;
            if (grid.get(xi + dx, yi + dy)) |cell| {
                if (cell == '@') count += 1;
            }
        }
    }
    return count;
}

const sample =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 13), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 43), try part2(std.testing.allocator, sample));
}
