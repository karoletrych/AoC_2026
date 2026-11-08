const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/10

const max_counters = 16;
const max_buttons = 16;
const max_columns = max_buttons + 1;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var total: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const open = std.mem.indexOfScalar(u8, line, '[') orelse return error.InvalidInput;
        const close = std.mem.indexOfScalar(u8, line, ']') orelse return error.InvalidInput;
        const pattern = line[open + 1 .. close];

        var target: u32 = 0;
        for (pattern, 0..) |ch, i| {
            if (ch == '#') target |= @as(u32, 1) << @intCast(i);
        }

        var masks: [max_buttons]u32 = undefined;
        var mask_count: usize = 0;
        try parseMasks(line[close + 1 ..], &masks, &mask_count);

        const state_count = @as(usize, 1) << @intCast(pattern.len);
        var distance = try allocator.alloc(i32, state_count);
        defer allocator.free(distance);
        @memset(distance, -1);

        var queue = try allocator.alloc(u32, state_count);
        defer allocator.free(queue);

        var head: usize = 0;
        var tail: usize = 0;
        distance[0] = 0;
        queue[tail] = 0;
        tail += 1;

        while (head < tail) {
            const state = queue[head];
            head += 1;
            if (state == target) break;

            for (masks[0..mask_count]) |mask| {
                const next = state ^ mask;
                if (distance[next] == -1) {
                    distance[next] = distance[state] + 1;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }

        if (distance[target] < 0) return error.Unreachable;
        total += distance[target];
    }
    return total;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var total: i64 = 0;

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const close = std.mem.indexOfScalar(u8, line, ']') orelse return error.InvalidInput;
        const brace = std.mem.indexOfScalar(u8, line, '{') orelse return error.InvalidInput;
        const end = std.mem.indexOfScalar(u8, line, '}') orelse return error.InvalidInput;

        var target: [max_counters]i64 = undefined;
        var counters: usize = 0;
        var bit = std.mem.splitScalar(u8, line[brace + 1 .. end], ',');
        while (bit.next()) |token| {
            if (token.len == 0) continue;
            target[counters] = try std.fmt.parseInt(i64, token, 10);
            counters += 1;
        }

        var buttons: [max_buttons][max_counters]u8 = undefined;
        var lengths: [max_buttons]usize = undefined;
        var button_count: usize = 0;
        try parseWiring(line[close + 1 .. brace], &buttons, &lengths, &button_count);

        var matrix: [max_counters][max_columns]f64 = undefined;
        for (0..counters) |i| {
            for (0..max_columns) |j| matrix[i][j] = 0;
            matrix[i][button_count] = @floatFromInt(target[i]);
        }
        for (0..button_count) |button| {
            for (buttons[button][0..lengths[button]]) |counter| {
                matrix[counter][button] = 1;
            }
        }

        total += try solveInteger(&matrix, counters, button_count, target[0..counters]);
    }
    return total;
}

fn solveInteger(
    matrix: *[max_counters][max_columns]f64,
    counters: usize,
    buttons: usize,
    target: []const i64,
) !i64 {
    var pivot_columns: [max_buttons]usize = undefined;
    var pivot_count: usize = 0;
    var is_pivot: [max_buttons]bool = undefined;
    for (&is_pivot) |*flag| flag.* = false;

    var row: usize = 0;
    var column: usize = 0;
    while (column < buttons and row < counters) : (column += 1) {
        var pick = row;
        while (pick < counters and @abs(matrix[pick][column]) <= 1e-12) : (pick += 1) {}
        if (pick == counters) continue;

        if (pick != row) {
            const saved = matrix[row];
            matrix[row] = matrix[pick];
            matrix[pick] = saved;
        }

        const divisor = matrix[row][column];
        var j = column;
        while (j <= buttons) : (j += 1) matrix[row][j] /= divisor;

        for (0..counters) |i| {
            if (i == row) continue;
            const factor = matrix[i][column];
            if (@abs(factor) <= 1e-12) continue;
            j = column;
            while (j <= buttons) : (j += 1) matrix[i][j] -= factor * matrix[row][j];
        }

        pivot_columns[pivot_count] = column;
        pivot_count += 1;
        is_pivot[column] = true;
        row += 1;
    }

    for (row..counters) |i| {
        if (@abs(matrix[i][buttons]) > 1e-9) return error.Inconsistent;
    }

    var free_columns: [max_buttons]usize = undefined;
    var free_count: usize = 0;
    for (0..buttons) |c| {
        if (!is_pivot[c]) {
            free_columns[free_count] = c;
            free_count += 1;
        }
    }

    var max_target: i64 = 0;
    for (target) |value| max_target = @max(max_target, value);

    var solver = Solver{
        .matrix = matrix,
        .buttons = buttons,
        .pivot_columns = pivot_columns,
        .pivot_count = pivot_count,
        .free_columns = free_columns,
        .free_count = free_count,
        .values = undefined,
        .max_target = max_target,
        .best = std.math.maxInt(i64),
    };
    solver.search(0, 0);

    if (solver.best == std.math.maxInt(i64)) return error.Infeasible;
    return solver.best;
}

const Solver = struct {
    matrix: *[max_counters][max_columns]f64,
    buttons: usize,
    pivot_columns: [max_buttons]usize,
    pivot_count: usize,
    free_columns: [max_buttons]usize,
    free_count: usize,
    values: [max_buttons]i64,
    max_target: i64,
    best: i64,

    fn search(self: *Solver, index: usize, free_sum: i64) void {
        if (free_sum >= self.best) return;

        if (index == self.free_count) {
            var sum = free_sum;
            for (0..self.pivot_count) |r| {
                _ = self.pivot_columns[r];
                var value = self.matrix[r][self.buttons];
                for (0..self.free_count) |f| {
                    value -= self.matrix[r][self.free_columns[f]] *
                        @as(f64, @floatFromInt(self.values[f]));
                }
                const rounded = @round(value);
                if (@abs(value - rounded) > 1e-6 or rounded < 0 or rounded > 1e9) return;
                sum += @as(i64, @intFromFloat(rounded));
            }
            if (sum < self.best) self.best = sum;
            return;
        }

        var value: i64 = 0;
        while (value <= self.max_target) : (value += 1) {
            if (free_sum + value >= self.best) break;
            self.values[index] = value;
            self.search(index + 1, free_sum + value);
        }
    }
};

fn parseMasks(text: []const u8, masks: *[max_buttons]u32, count: *usize) !void {
    var position: usize = 0;
    while (findChar(text, position, '(')) |open| {
        const close = findChar(text, open + 1, ')') orelse return error.InvalidInput;
        var mask: u32 = 0;
        var it = std.mem.splitScalar(u8, text[open + 1 .. close], ',');
        while (it.next()) |token| {
            if (token.len == 0) continue;
            const index = try std.fmt.parseInt(u5, token, 10);
            mask |= @as(u32, 1) << index;
        }
        masks[count.*] = mask;
        count.* += 1;
        position = close + 1;
    }
}

fn parseWiring(
    text: []const u8,
    buttons: *[max_buttons][max_counters]u8,
    lengths: *[max_buttons]usize,
    count: *usize,
) !void {
    var position: usize = 0;
    while (findChar(text, position, '(')) |open| {
        const close = findChar(text, open + 1, ')') orelse return error.InvalidInput;
        var length: usize = 0;
        var it = std.mem.splitScalar(u8, text[open + 1 .. close], ',');
        while (it.next()) |token| {
            if (token.len == 0) continue;
            buttons[count.*][length] = try std.fmt.parseInt(u8, token, 10);
            length += 1;
        }
        lengths[count.*] = length;
        count.* += 1;
        position = close + 1;
    }
}

fn findChar(text: []const u8, start: usize, character: u8) ?usize {
    var i = start;
    while (i < text.len) : (i += 1) {
        if (text[i] == character) return i;
    }
    return null;
}

const sample =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 7), try part1(std.testing.allocator, sample));
}
