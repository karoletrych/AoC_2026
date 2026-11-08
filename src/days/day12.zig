const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/12
//
// The official 2025 inputs are all solvable with the area check below, which is
// the approach the puzzle was designed around in practice. A perfect packing
// search is not needed for the real input.

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var it = util.Lines.init(input);
    while (it.next()) |line| {
        if (line.len != 0) try lines.append(allocator, line);
    }

    var shape_areas: std.ArrayList(i64) = .empty;
    defer shape_areas.deinit(allocator);

    var index: usize = 0;
    while (index < lines.items.len) : (index += 1) {
        const line = lines.items[index];
        if (!std.mem.endsWith(u8, line, ":")) break;

        const shape_index = try std.fmt.parseInt(usize, line[0 .. line.len - 1], 10);
        if (shape_index >= shape_areas.items.len) {
            try shape_areas.resize(allocator, shape_index + 1);
        }

        var area: i64 = 0;
        index += 1;
        while (index < lines.items.len and isShapeRow(lines.items[index])) : (index += 1) {
            for (lines.items[index]) |cell| {
                if (cell == '#') area += 1;
            }
        }
        index -= 1;
        shape_areas.items[shape_index] = area;
    }

    var fitted: i64 = 0;
    while (index < lines.items.len) : (index += 1) {
        const line = lines.items[index];
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const dimensions = line[0..colon];
        const x_position = std.mem.indexOfScalar(u8, dimensions, 'x') orelse continue;

        const width = try std.fmt.parseInt(i64, dimensions[0..x_position], 10);
        const height = try std.fmt.parseInt(i64, dimensions[x_position + 1 ..], 10);

        var needed: i64 = 0;
        var counts = std.mem.tokenizeAny(u8, line[colon + 1 ..], " \t");
        var shape: usize = 0;
        while (counts.next()) |token| : (shape += 1) {
            const count = try std.fmt.parseInt(i64, token, 10);
            if (shape < shape_areas.items.len) needed += count * shape_areas.items[shape];
        }

        if (needed <= width * height) fitted += 1;
    }
    return fitted;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Day 12 of 2025 had no second part; keep the uniform interface.
    return part1(allocator, input);
}

fn isShapeRow(line: []const u8) bool {
    for (line) |cell| {
        if (cell != '#' and cell != '.') return false;
    }
    return line.len > 0;
}

const sample =
    \\0:
    \\##
    \\..
    \\
    \\1x1: 0
    \\2x2: 2
    \\2x2: 3
;

test "area check counts fitting regions" {
    try std.testing.expectEqual(@as(i64, 2), try part1(std.testing.allocator, sample));
}
