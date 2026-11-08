const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/9

const Point = struct {
    x: i64,
    y: i64,
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const points = try parsePoints(allocator, input);
    defer allocator.free(points);

    var best: i64 = 0;
    for (0..points.len) |a| {
        for (a + 1..points.len) |b| {
            const area = rectArea(points[a], points[b]);
            if (area > best) best = area;
        }
    }
    return best;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const points = try parsePoints(allocator, input);
    defer allocator.free(points);
    if (points.len < 3) return 0;

    const rank_x = try allocator.alloc(usize, points.len);
    defer allocator.free(rank_x);
    const rank_y = try allocator.alloc(usize, points.len);
    defer allocator.free(rank_y);

    const xs = try uniqueSorted(allocator, points, true);
    defer allocator.free(xs);
    const ys = try uniqueSorted(allocator, points, false);
    defer allocator.free(ys);

    for (points, 0..) |point, i| {
        rank_x[i] = lowerBound(xs, point.x);
        rank_y[i] = lowerBound(ys, point.y);
    }

    const cell_x = xs.len - 1;
    const cell_y = ys.len - 1;

    const inside = try allocator.alloc(u8, cell_x * cell_y);
    defer allocator.free(inside);
    @memset(inside, 0);

    const crossings = try allocator.alloc(i64, points.len);
    defer allocator.free(crossings);

    var j: usize = 0;
    while (j < cell_y) : (j += 1) {
        const y2 = ys[j] + ys[j + 1];
        var count: usize = 0;
        for (0..points.len) |k| {
            const a = points[k];
            const b = points[(k + 1) % points.len];
            if (a.x != b.x) continue;
            const y_min = @min(a.y, b.y) * 2;
            const y_max = @max(a.y, b.y) * 2;
            if (y_min < y2 and y2 < y_max) {
                crossings[count] = a.x;
                count += 1;
            }
        }
        sortI64(crossings[0..count]);

        for (0..cell_x) |i| {
            const x2 = xs[i] + xs[i + 1];
            var in = false;
            var p: usize = 0;
            while (p + 1 < count) : (p += 2) {
                if (crossings[p] * 2 < x2 and x2 < crossings[p + 1] * 2) {
                    in = true;
                    break;
                }
            }
            inside[j * cell_x + i] = @intFromBool(in);
        }
    }

    const stride = cell_x + 1;
    const prefix = try allocator.alloc(u32, stride * (cell_y + 1));
    defer allocator.free(prefix);
    @memset(prefix, 0);
    for (0..cell_y) |row| {
        for (0..cell_x) |col| {
            prefix[(row + 1) * stride + col + 1] =
                inside[row * cell_x + col] +
                prefix[row * stride + col + 1] +
                prefix[(row + 1) * stride + col] -
                prefix[row * stride + col];
        }
    }

    var best: i64 = 0;
    for (0..points.len) |a| {
        for (a + 1..points.len) |b| {
            const area = rectArea(points[a], points[b]);
            if (area <= best) continue;

            const x0 = @min(rank_x[a], rank_x[b]);
            const x1 = @max(rank_x[a], rank_x[b]);
            const y0 = @min(rank_y[a], rank_y[b]);
            const y1 = @max(rank_y[a], rank_y[b]);

            const cells: i64 = @intCast((x1 - x0) * (y1 - y0));
            const got: i64 = @as(i64, prefix[y1 * stride + x1]) -
                @as(i64, prefix[y0 * stride + x1]) -
                @as(i64, prefix[y1 * stride + x0]) +
                @as(i64, prefix[y0 * stride + x0]);

            if (got != cells) continue;
            best = area;
        }
    }
    return best;
}

fn rectArea(a: Point, b: Point) i64 {
    const width: i64 = @intCast(@abs(a.x - b.x) + 1);
    const height: i64 = @intCast(@abs(a.y - b.y) + 1);
    return width * height;
}

fn parsePoints(allocator: std.mem.Allocator, input: []const u8) ![]Point {
    var points: std.ArrayList(Point) = .empty;
    defer points.deinit(allocator);

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const comma = std.mem.indexOfScalar(u8, line, ',') orelse return error.InvalidInput;
        try points.append(allocator, .{
            .x = try std.fmt.parseInt(i64, line[0..comma], 10),
            .y = try std.fmt.parseInt(i64, line[comma + 1 ..], 10),
        });
    }
    return points.toOwnedSlice(allocator);
}

fn uniqueSorted(allocator: std.mem.Allocator, points: []const Point, comptime x_axis: bool) ![]i64 {
    const values = try allocator.alloc(i64, points.len);
    for (points, 0..) |point, i| values[i] = if (x_axis) point.x else point.y;
    std.sort.pdq(i64, values, {}, std.sort.asc(i64));

    var len: usize = 0;
    for (values) |value| {
        if (len == 0 or values[len - 1] != value) {
            values[len] = value;
            len += 1;
        }
    }
    return allocator.realloc(values, len);
}

fn lowerBound(values: []const i64, target: i64) usize {
    var low: usize = 0;
    var high: usize = values.len;
    while (low < high) {
        const mid = low + (high - low) / 2;
        if (values[mid] < target) low = mid + 1 else high = mid;
    }
    return low;
}

fn sortI64(values: []i64) void {
    var i: usize = 1;
    while (i < values.len) : (i += 1) {
        var j = i;
        while (j > 0 and values[j - 1] > values[j]) : (j -= 1) {
            std.mem.swap(i64, &values[j - 1], &values[j]);
        }
    }
}

const sample =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 50), try part1(std.testing.allocator, sample));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 24), try part2(std.testing.allocator, sample));
}
