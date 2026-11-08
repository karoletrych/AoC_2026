const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/5

const Range = struct {
    start: i64,
    end: i64,
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(allocator);
    var ids: std.ArrayList(i64) = .empty;
    defer ids.deinit(allocator);
    try parse(allocator, input, &ranges, &ids);

    var fresh: i64 = 0;
    for (ids.items) |id| {
        for (ranges.items) |range| {
            if (id >= range.start and id <= range.end) {
                fresh += 1;
                break;
            }
        }
    }
    return fresh;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(allocator);
    var ids: std.ArrayList(i64) = .empty;
    defer ids.deinit(allocator);
    try parse(allocator, input, &ranges, &ids);

    const items = ranges.items;
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and items[j - 1].start > items[j].start) : (j -= 1) {
            std.mem.swap(Range, &items[j - 1], &items[j]);
        }
    }

    var total: i64 = 0;
    var current = items[0];
    for (items[1..]) |range| {
        if (range.start <= current.end + 1) {
            current.end = @max(current.end, range.end);
        } else {
            total += current.end - current.start + 1;
            current = range;
        }
    }
    total += current.end - current.start + 1;
    return total;
}

fn parse(
    allocator: std.mem.Allocator,
    input: []const u8,
    ranges: *std.ArrayList(Range),
    ids: *std.ArrayList(i64),
) !void {
    var in_ranges = true;
    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) {
            in_ranges = false;
            continue;
        }

        if (in_ranges) {
            const dash = std.mem.indexOfScalar(u8, line, '-') orelse return error.InvalidInput;
            try ranges.append(allocator, .{
                .start = try std.fmt.parseInt(i64, line[0..dash], 10),
                .end = try std.fmt.parseInt(i64, line[dash + 1 ..], 10),
            });
        } else {
            try ids.append(allocator, try std.fmt.parseInt(i64, line, 10));
        }
    }
}

const sample =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 3), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 14), try part2(std.testing.allocator, sample));
}
