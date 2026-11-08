const std = @import("std");

/// Reads `inputs/dayNN.txt` into memory owned by `gpa`.
pub fn readDayInput(io: std.Io, gpa: std.mem.Allocator, day: u8) ![]u8 {
    var path_buf: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "inputs/day{d:0>2}.txt", .{day});
    return std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .limited(64 * 1024 * 1024));
}

/// Iterates over lines, stripping a trailing carriage return from each one.
pub const Lines = struct {
    inner: std.mem.SplitIterator(u8, .scalar),

    pub fn init(input: []const u8) Lines {
        return .{ .inner = std.mem.splitScalar(u8, input, '\n') };
    }

    pub fn next(self: *Lines) ?[]const u8 {
        const line = self.inner.next() orelse return null;
        return std.mem.trimEnd(u8, line, "\r");
    }
};

test "Lines splits on LF and trims CR" {
    var lines = Lines.init("alpha\r\nbeta\ngamma");
    try std.testing.expectEqualStrings("alpha", lines.next().?);
    try std.testing.expectEqualStrings("beta", lines.next().?);
    try std.testing.expectEqualStrings("gamma", lines.next().?);
    try std.testing.expectEqual(@as(?[]const u8, null), lines.next());
}
