const std = @import("std");
const util = @import("../util.zig");

// https://adventofcode.com/2025/day/11

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var graph = try Graph.parse(allocator, input);
    defer graph.deinit(allocator);

    const from = graph.lookup("you") orelse return error.NoYou;
    const to = graph.lookup("out") orelse return error.NoOut;
    return graph.countPaths(allocator, from, to);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var graph = try Graph.parse(allocator, input);
    defer graph.deinit(allocator);

    const svr = graph.lookup("svr") orelse return error.NoSvr;
    const dac = graph.lookup("dac") orelse return error.NoDac;
    const fft = graph.lookup("fft") orelse return error.NoFft;
    const out = graph.lookup("out") orelse return error.NoOut;

    const svr_fft = try graph.countPaths(allocator, svr, fft);
    const fft_dac = try graph.countPaths(allocator, fft, dac);
    const dac_out = try graph.countPaths(allocator, dac, out);
    const svr_dac = try graph.countPaths(allocator, svr, dac);
    const dac_fft = try graph.countPaths(allocator, dac, fft);
    const fft_out = try graph.countPaths(allocator, fft, out);

    const first: i128 = @as(i128, svr_fft) * fft_dac * dac_out;
    const second: i128 = @as(i128, svr_dac) * dac_fft * fft_out;
    return @intCast(first + second);
}

const Graph = struct {
    edges: []std.ArrayList(u32),
    index: std.StringHashMap(u32),

    fn parse(allocator: std.mem.Allocator, input: []const u8) !Graph {
        var index = std.StringHashMap(u32).init(allocator);
        errdefer index.deinit();

        var lines = util.Lines.init(input);
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            try addName(&index, std.mem.trim(u8, line[0..colon], " \t"));

            var outputs = std.mem.tokenizeAny(u8, line[colon + 1 ..], " \t");
            while (outputs.next()) |output| try addName(&index, output);
        }
        if (!index.contains("out")) try addName(&index, "out");

        const edges = try allocator.alloc(std.ArrayList(u32), index.count());
        errdefer allocator.free(edges);
        for (edges) |*list| list.* = .empty;
        errdefer for (edges) |*list| list.deinit(allocator);

        var second_pass = util.Lines.init(input);
        while (second_pass.next()) |line| {
            if (line.len == 0) continue;
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const from = index.get(std.mem.trim(u8, line[0..colon], " \t")) orelse return error.InvalidInput;

            var outputs = std.mem.tokenizeAny(u8, line[colon + 1 ..], " \t");
            while (outputs.next()) |output| {
                const to = index.get(output) orelse return error.InvalidInput;
                try edges[from].append(allocator, to);
            }
        }

        return .{ .edges = edges, .index = index };
    }

    fn deinit(self: *Graph, allocator: std.mem.Allocator) void {
        for (self.edges) |*list| list.deinit(allocator);
        allocator.free(self.edges);
        self.index.deinit();
    }

    fn lookup(self: Graph, name: []const u8) ?u32 {
        return self.index.get(name);
    }

    fn countPaths(self: Graph, allocator: std.mem.Allocator, from: u32, to: u32) !i64 {
        const memo = try allocator.alloc(i64, self.edges.len);
        defer allocator.free(memo);
        @memset(memo, -1);
        return countRecursive(self.edges, from, to, memo);
    }
};

fn countRecursive(edges: []const std.ArrayList(u32), from: u32, to: u32, memo: []i64) i64 {
    if (from == to) return 1;
    const position: usize = from;
    if (memo[position] >= 0) return memo[position];

    var total: i64 = 0;
    for (edges[position].items) |next| {
        total += countRecursive(edges, next, to, memo);
    }
    memo[position] = total;
    return total;
}

fn addName(index: *std.StringHashMap(u32), name: []const u8) !void {
    if (index.contains(name)) return;
    try index.put(name, @intCast(index.count()));
}

const sample_part1 =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: out
;

const sample_part2 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
;

test "part 1 sample" {
    try std.testing.expectEqual(@as(i64, 5), try part1(std.testing.allocator, sample_part1));
}

test "part 2 sample" {
    try std.testing.expectEqual(@as(i64, 2), try part2(std.testing.allocator, sample_part2));
}
