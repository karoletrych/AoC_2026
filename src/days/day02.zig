const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/2

const Mode = enum { twice, any_repeat };

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    return solve(input, .twice);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    return solve(input, .any_repeat);
}

fn solve(input: []const u8, mode: Mode) !i64 {
    var total: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var ranges = std.mem.splitScalar(u8, line, ',');
        while (ranges.next()) |range| {
            const dash = std.mem.indexOfScalar(u8, range, '-') orelse return error.InvalidInput;
            const start = try std.fmt.parseInt(u64, range[0..dash], 10);
            const end = try std.fmt.parseInt(u64, range[dash + 1 ..], 10);

            var number = start;
            while (true) {
                var buf: [24]u8 = undefined;
                const text = std.fmt.bufPrint(&buf, "{d}", .{number}) catch unreachable;

                const invalid = switch (mode) {
                    .twice => isRepeated(text, 2),
                    .any_repeat => isRepeatedAny(text),
                };
                if (invalid) total += @intCast(number);

                if (number == end) break;
                number += 1;
            }
        }
    }
    return total;
}

fn isRepeated(text: []const u8, times: usize) bool {
    if (times < 2 or text.len % times != 0) return false;
    const part_len = text.len / times;
    const first = text[0..part_len];
    var i: usize = 1;
    while (i < times) : (i += 1) {
        if (!std.mem.eql(u8, first, text[i * part_len ..][0..part_len])) return false;
    }
    return true;
}

fn isRepeatedAny(text: []const u8) bool {
    var times: usize = 2;
    while (times <= text.len) : (times += 1) {
        if (isRepeated(text, times)) return true;
    }
    return false;
}

const sample =
    "11-22,95-115,998-1012,1188511880-1188511890,222220-222224," ++
    "1698522-1698528,446443-446449,38593856-38593862,565653-565659," ++
    "824824821-824824827,2121212118-2121212124";

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 1227775554), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 4174379265), try part2(std.testing.allocator, sample));
}
