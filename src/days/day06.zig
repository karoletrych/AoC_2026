const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/6

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    var it = util.Lines.init(input);
    while (it.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, line);
    }
    if (lines.items.len < 2) return 0;

    const numeric = lines.items[0 .. lines.items.len - 1];
    const operators = lines.items[lines.items.len - 1];

    var tokens = try allocator.alloc(std.ArrayList([]const u8), numeric.len);
    defer allocator.free(tokens);
    defer for (tokens) |*row| row.deinit(allocator);

    for (numeric, 0..) |line, row| {
        tokens[row] = .empty;
        var tit = std.mem.tokenizeAny(u8, line, " \t");
        while (tit.next()) |token| try tokens[row].append(allocator, token);
    }

    var total: i64 = 0;
    var op_it = std.mem.tokenizeAny(u8, operators, " \t");
    var problem: usize = 0;
    while (op_it.next()) |op_token| : (problem += 1) {
        const op = op_token[0];
        var value: i64 = if (op == '*') 1 else 0;
        for (tokens) |row| {
            if (problem >= row.items.len) return error.InvalidInput;
            const number = try std.fmt.parseInt(i64, row.items[problem], 10);
            if (op == '*') value *= number else value += number;
        }
        total += value;
    }
    return total;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try util.fromLines(allocator, input);
    defer grid.deinit();

    var buffer: std.ArrayList(i64) = .empty;
    defer buffer.deinit(allocator);

    var total: i64 = 0;
    var op: u8 = 0;

    var x = grid.width;
    while (x > 0) {
        x -= 1;

        var blank = true;
        for (0..grid.height) |y| {
            if (grid.at(x, y) != ' ') {
                blank = false;
                break;
            }
        }

        if (blank) {
            if (buffer.items.len > 0) {
                total += apply(op, buffer.items);
                buffer.clearRetainingCapacity();
            }
            continue;
        }

        var number: i64 = 0;
        var place: i64 = 1;
        var y = grid.height;
        while (y > 0) {
            y -= 1;
            const cell = grid.at(x, y);
            if (cell == '+' or cell == '*') op = cell;
            if (cell < '0' or cell > '9') continue;
            number += @as(i64, cell - '0') * place;
            place *= 10;
        }
        try buffer.append(allocator, number);
    }

    if (buffer.items.len > 0) total += apply(op, buffer.items);
    return total;
}

fn apply(op: u8, values: []const i64) i64 {
    var result: i64 = if (op == '*') 1 else 0;
    for (values) |value| {
        if (op == '*') result *= value else result += value;
    }
    return result;
}
