const std = @import("std");

/// Integer 3D vector, a port of the C# `IntVector` record struct.
///
/// Plain structs are hashable by value, so `std.AutoHashMap(Vec3, V)` works
/// directly without a custom hash implementation.
pub const Vec3 = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn init(x: i64, y: i64, z: i64) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn eql(a: Vec3, b: Vec3) bool {
        return a.x == b.x and a.y == b.y and a.z == b.z;
    }

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn scale(v: Vec3, factor: i64) Vec3 {
        return .{ .x = v.x * factor, .y = v.y * factor, .z = v.z * factor };
    }

    pub fn manhattan(a: Vec3, b: Vec3) u64 {
        return @abs(a.x - b.x) + @abs(a.y - b.y) + @abs(a.z - b.z);
    }

    /// Euclidean distance, matching the original `IntVector.Distance`.
    pub fn distance(a: Vec3, b: Vec3) f64 {
        const dx: f64 = @floatFromInt(a.x - b.x);
        const dy: f64 = @floatFromInt(a.y - b.y);
        const dz: f64 = @floatFromInt(a.z - b.z);
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    /// Squared Euclidean distance. Use this when only ordering matters:
    /// it avoids `sqrt` and keeps comparisons exact.
    pub fn distanceSquared(a: Vec3, b: Vec3) u64 {
        const dx = a.x - b.x;
        const dy = a.y - b.y;
        const dz = a.z - b.z;
        return @intCast(dx * dx + dy * dy + dz * dz);
    }

    pub fn format(self: Vec3, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{d},{d},{d}", .{ self.x, self.y, self.z });
    }
};

test "Vec3 arithmetic and distance" {
    const a = Vec3.init(1, 2, 3);
    const b = Vec3.init(4, 6, 3);

    try std.testing.expect(Vec3.eql(.{ .x = 1, .y = 2, .z = 3 }, a));
    try std.testing.expect(Vec3.eql(.{ .x = 5, .y = 8, .z = 6 }, Vec3.add(a, b)));
    try std.testing.expect(Vec3.eql(.{ .x = 2, .y = 4, .z = 6 }, Vec3.scale(a, 2)));
    try std.testing.expectEqual(@as(u64, 7), Vec3.manhattan(a, b));
    try std.testing.expectEqual(@as(f64, 5.0), Vec3.distance(a, b));
    try std.testing.expectEqual(@as(u64, 25), Vec3.distanceSquared(a, b));
}

test "Vec3 formats as x,y,z" {
    const text = try std.fmt.allocPrint(std.testing.allocator, "{f}", .{Vec3.init(1, 2, 3)});
    defer std.testing.allocator.free(text);
    try std.testing.expectEqualStrings("1,2,3", text);
}

test "Vec3 works as a hash map key" {
    var seen = std.AutoHashMap(Vec3, void).init(std.testing.allocator);
    defer seen.deinit();

    try seen.put(Vec3.init(1, 2, 3), {});
    try seen.put(Vec3.init(1, 2, 3), {});
    try seen.put(Vec3.init(3, 2, 1), {});
    try std.testing.expectEqual(@as(usize, 2), seen.count());
}
