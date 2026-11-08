const std = @import("std");

pub const Point = struct {
    x: usize,
    y: usize,
};

/// Rectangular 2D grid addressed as `(x, y)`, like the C# `T[,]` helper.
///
/// Cells are stored row-major in a single allocation. Out-of-bounds lookups are
/// available through `get`, which takes signed coordinates and returns null.
pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        width: usize,
        height: usize,
        cells: []T,

        pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
            return .{
                .allocator = allocator,
                .width = width,
                .height = height,
                .cells = try allocator.alloc(T, width * height),
            };
        }

        pub fn initFilled(
            allocator: std.mem.Allocator,
            width: usize,
            height: usize,
            value: T,
        ) !Self {
            const result = try init(allocator, width, height);
            @memset(result.cells, value);
            return result;
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.cells);
        }

        pub fn inBounds(self: Self, x: isize, y: isize) bool {
            return x >= 0 and y >= 0 and
                @as(usize, @intCast(x)) < self.width and
                @as(usize, @intCast(y)) < self.height;
        }

        /// Bounds-checked access with signed coordinates.
        pub fn get(self: Self, x: isize, y: isize) ?T {
            if (!self.inBounds(x, y)) return null;
            return self.at(@intCast(x), @intCast(y));
        }

        pub fn at(self: Self, x: usize, y: usize) T {
            std.debug.assert(x < self.width and y < self.height);
            return self.cells[y * self.width + x];
        }

        pub fn set(self: *Self, x: usize, y: usize, value: T) void {
            std.debug.assert(x < self.width and y < self.height);
            self.cells[y * self.width + x] = value;
        }

        pub fn row(self: Self, y: usize) []T {
            std.debug.assert(y < self.height);
            return self.cells[y * self.width ..][0..self.width];
        }

        pub fn column(self: Self, allocator: std.mem.Allocator, x: usize) ![]T {
            std.debug.assert(x < self.width);
            const result = try allocator.alloc(T, self.height);
            for (result, 0..) |*cell, y| cell.* = self.at(x, y);
            return result;
        }

        pub fn find(self: Self, value: T) ?Point {
            for (0..self.height) |y| {
                for (0..self.width) |x| {
                    if (std.meta.eql(self.at(x, y), value)) return .{ .x = x, .y = y };
                }
            }
            return null;
        }

        pub fn transpose(self: Self, allocator: std.mem.Allocator) !Grid(T) {
            var result = try Grid(T).init(allocator, self.height, self.width);
            for (0..self.height) |y| {
                for (0..self.width) |x| {
                    result.set(y, x, self.at(x, y));
                }
            }
            return result;
        }

        /// Writes the grid row by row; `u8` grids are printed as characters.
        pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            for (0..self.height) |y| {
                for (self.row(y)) |cell| {
                    if (T == u8) {
                        try writer.writeByte(cell);
                    } else {
                        try writer.print("{d} ", .{cell});
                    }
                }
                try writer.writeByte('\n');
            }
        }
    };
}

/// Builds a character grid from newline-separated lines, padding shorter lines
/// with spaces. Handles both LF and CRLF input.
pub fn fromLines(allocator: std.mem.Allocator, input: []const u8) !Grid(u8) {
    const trimmed = std.mem.trimEnd(u8, input, "\r\n");
    if (trimmed.len == 0) return Grid(u8).init(allocator, 0, 0);

    var width: usize = 0;
    var height: usize = 0;
    var lines = std.mem.splitScalar(u8, trimmed, '\n');
    while (lines.next()) |raw| {
        width = @max(width, std.mem.trimEnd(u8, raw, "\r").len);
        height += 1;
    }

    var result = try Grid(u8).initFilled(allocator, width, height, ' ');
    var y: usize = 0;
    lines = std.mem.splitScalar(u8, trimmed, '\n');
    while (lines.next()) |raw| : (y += 1) {
        const line = std.mem.trimEnd(u8, raw, "\r");
        @memcpy(result.cells[y * width ..][0..line.len], line);
    }
    return result;
}

test "fromLines handles CRLF and ragged lines" {
    var grid = try fromLines(std.testing.allocator, "abc\r\nde\n");
    defer grid.deinit();

    try std.testing.expectEqual(@as(usize, 3), grid.width);
    try std.testing.expectEqual(@as(usize, 2), grid.height);
    try std.testing.expectEqual(@as(u8, 'a'), grid.at(0, 0));
    try std.testing.expectEqual(@as(u8, 'e'), grid.get(1, 1).?);
    try std.testing.expectEqual(@as(?u8, null), grid.get(-1, 0));
    try std.testing.expectEqualStrings("de ", grid.row(1));
}

test "grid find and transpose" {
    const allocator = std.testing.allocator;
    var grid = try fromLines(allocator, "abc\ndef\n");
    defer grid.deinit();

    const found = grid.find('e').?;
    try std.testing.expectEqual(@as(usize, 1), found.x);
    try std.testing.expectEqual(@as(usize, 1), found.y);

    var transposed = try grid.transpose(allocator);
    defer transposed.deinit();
    try std.testing.expectEqual(@as(usize, 2), transposed.width);
    try std.testing.expectEqual(@as(usize, 3), transposed.height);
    try std.testing.expectEqual(@as(u8, 'b'), transposed.at(0, 1));
    try std.testing.expectEqual(@as(u8, 'd'), transposed.at(1, 0));

    const first_column = try grid.column(allocator, 0);
    defer allocator.free(first_column);
    try std.testing.expectEqualStrings("ad", first_column);
}

test "grid formats as text" {
    var grid = try fromLines(std.testing.allocator, "ab\ncd\n");
    defer grid.deinit();

    const text = try std.fmt.allocPrint(std.testing.allocator, "{f}", .{grid});
    defer std.testing.allocator.free(text);
    try std.testing.expectEqualStrings("ab\ncd\n", text);
}
