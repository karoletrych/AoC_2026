const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/8

const Pair = struct {
    distance: u64,
    a: u32,
    b: u32,
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const points = try parsePoints(allocator, input);
    defer allocator.free(points);
    const pairs = try buildPairs(allocator, points);
    defer allocator.free(pairs);

    var dsu = try Dsu.init(allocator, points.len);
    defer dsu.deinit(allocator);

    const limit = @min(pairs.len, 1000);
    for (pairs[0..limit]) |pair| _ = dsu.unite(pair.a, pair.b);

    var sizes: std.ArrayList(i64) = .empty;
    defer sizes.deinit(allocator);
    for (0..points.len) |i| {
        if (dsu.parent[i] == i) try sizes.append(allocator, @intCast(dsu.size[i]));
    }
    std.sort.pdq(i64, sizes.items, {}, std.sort.desc(i64));

    var product: i64 = 1;
    for (sizes.items[0..@min(3, sizes.items.len)]) |size| product *= size;
    return product;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const points = try parsePoints(allocator, input);
    defer allocator.free(points);
    const pairs = try buildPairs(allocator, points);
    defer allocator.free(pairs);

    var dsu = try Dsu.init(allocator, points.len);
    defer dsu.deinit(allocator);
    var components = points.len;

    for (pairs) |pair| {
        if (dsu.unite(pair.a, pair.b)) {
            components -= 1;
            if (components == 1) {
                return points[pair.a].x * points[pair.b].x;
            }
        }
    }
    return error.NotConnected;
}

const Dsu = struct {
    parent: []u32,
    size: []u32,

    fn init(allocator: std.mem.Allocator, n: usize) !Dsu {
        const parent = try allocator.alloc(u32, n);
        errdefer allocator.free(parent);
        const size = try allocator.alloc(u32, n);
        for (parent, 0..) |*value, i| value.* = @intCast(i);
        @memset(size, 1);
        return .{ .parent = parent, .size = size };
    }

    fn deinit(self: *Dsu, allocator: std.mem.Allocator) void {
        allocator.free(self.parent);
        allocator.free(self.size);
    }

    fn find(self: *Dsu, node: u32) u32 {
        var root = node;
        while (self.parent[root] != root) root = self.parent[root];
        var current = node;
        while (self.parent[current] != current) {
            const next = self.parent[current];
            self.parent[current] = root;
            current = next;
        }
        return root;
    }

    fn unite(self: *Dsu, a: u32, b: u32) bool {
        var root_a = self.find(a);
        var root_b = self.find(b);
        if (root_a == root_b) return false;
        if (self.size[root_a] < self.size[root_b]) {
            const swap = root_a;
            root_a = root_b;
            root_b = swap;
        }
        self.parent[root_b] = root_a;
        self.size[root_a] += self.size[root_b];
        return true;
    }
};

fn parsePoints(allocator: std.mem.Allocator, input: []const u8) ![]util.Vec3 {
    var points: std.ArrayList(util.Vec3) = .empty;
    defer points.deinit(allocator);

    var lines = util.Lines.init(input);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var it = std.mem.splitScalar(u8, line, ',');
        try points.append(allocator, util.Vec3.init(
            try std.fmt.parseInt(i64, it.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, it.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, it.next() orelse return error.InvalidInput, 10),
        ));
    }
    return points.toOwnedSlice(allocator);
}

fn buildPairs(allocator: std.mem.Allocator, points: []const util.Vec3) ![]Pair {
    const count = points.len * (points.len - 1) / 2;
    const pairs = try allocator.alloc(Pair, count);

    var index: usize = 0;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            pairs[index] = .{
                .distance = util.Vec3.distanceSquared(points[i], points[j]),
                .a = @intCast(i),
                .b = @intCast(j),
            };
            index += 1;
        }
    }

    std.sort.pdq(Pair, pairs, {}, pairLessThan);
    return pairs;
}

fn pairLessThan(_: void, a: Pair, b: Pair) bool {
    if (a.distance != b.distance) return a.distance < b.distance;
    if (a.a != b.a) return a.a < b.a;
    return a.b < b.b;
}
