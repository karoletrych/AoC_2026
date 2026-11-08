const std = @import("std");

/// Iterator over every permutation of the given items (Heap's algorithm).
/// The returned slice is reused between iterations.
pub fn Permutations(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        items: []T,
        state: []usize,
        index: usize,
        started: bool,

        pub fn init(allocator: std.mem.Allocator, items: []const T) !Self {
            const owned = try allocator.dupe(T, items);
            errdefer allocator.free(owned);

            const state = try allocator.alloc(usize, items.len);
            @memset(state, 0);

            return .{
                .allocator = allocator,
                .items = owned,
                .state = state,
                .index = 0,
                .started = false,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
            self.allocator.free(self.state);
        }

        /// Returns the next permutation, or null once all have been produced.
        /// An empty input yields no permutations.
        pub fn next(self: *Self) ?[]const T {
            if (self.items.len == 0) return null;

            if (!self.started) {
                self.started = true;
                return self.items;
            }

            while (self.index < self.items.len) {
                if (self.state[self.index] < self.index) {
                    const other = if (self.index % 2 == 0) 0 else self.state[self.index];
                    std.mem.swap(T, &self.items[other], &self.items[self.index]);
                    self.state[self.index] += 1;
                    self.index = 0;
                    return self.items;
                }
                self.state[self.index] = 0;
                self.index += 1;
            }
            return null;
        }
    };
}

test "permutations of three items" {
    const allocator = std.testing.allocator;

    var permutations = try Permutations(u8).init(allocator, &[_]u8{ 1, 2, 3 });
    defer permutations.deinit();

    var count: usize = 0;
    var unique = std.AutoHashMap(u24, void).init(allocator);
    defer unique.deinit();

    while (permutations.next()) |perm| {
        count += 1;
        const key: u24 = @as(u24, perm[0]) << 16 | @as(u24, perm[1]) << 8 | perm[2];
        try unique.put(key, {});
    }

    try std.testing.expectEqual(@as(usize, 6), count);
    try std.testing.expectEqual(@as(usize, 6), unique.count());
}

test "permutations of an empty slice" {
    var permutations = try Permutations(u8).init(std.testing.allocator, &[_]u8{});
    defer permutations.deinit();
    try std.testing.expectEqual(@as(?[]const u8, null), permutations.next());
}
