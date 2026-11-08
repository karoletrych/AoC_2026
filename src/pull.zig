const std = @import("std");

const default_year = 2026;
const user_agent = "github.com/karoletrych/AoC_2026 (puzzle input fetcher)";

const usage =
    \\Usage: zig build pull -- <day> [year]
    \\
    \\Downloads your Advent of Code puzzle input to inputs/dayNN.txt.
    \\The year defaults to 2026; use it to fetch older puzzles.
    \\
    \\Authentication, in order of preference:
    \\  1. AOC_SESSION environment variable
    \\  2. .aoc-session file in the repository root (git-ignored)
    \\
    \\The session value is the "session" cookie from a logged-in
    \\adventofcode.com browser session.
    \\
;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);

    if (args.len < 2) return printUsage(io);

    const day = std.fmt.parseInt(u8, args[1], 10) catch return printUsage(io);
    if (day < 1 or day > 25) return printUsage(io);

    const year = if (args.len >= 3)
        std.fmt.parseInt(u16, args[2], 10) catch return printUsage(io)
    else
        2026;

    const session = resolveSession(init, arena) catch |err| {
        std.debug.print("cannot read AOC session: {s}\n", .{@errorName(err)});
        std.debug.print("Set AOC_SESSION or create a .aoc-session file.\n", .{});
        std.process.exit(1);
    };

    const url = try std.fmt.allocPrint(
        arena,
        "https://adventofcode.com/{d}/day/{d}/input",
        .{ year, day },
    );
    const cookie = try std.fmt.allocPrint(arena, "session={s}", .{session});

    var client: std.http.Client = .{ .allocator = arena, .io = io };
    defer client.deinit();

    var response: std.Io.Writer.Allocating = .init(arena);
    defer response.deinit();

    const result = client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &response.writer,
        .extra_headers = &.{
            .{ .name = "Cookie", .value = cookie },
            .{ .name = "User-Agent", .value = user_agent },
        },
    }) catch |err| {
        std.debug.print("request to adventofcode.com failed: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };

    if (result.status != .ok) {
        std.debug.print("adventofcode.com returned {d} {s}\n", .{
            @backingInt(result.status),
            result.status.phrase() orelse "",
        });
        switch (result.status) {
            .bad_request => std.debug.print(
                "Check that the session cookie is valid and that the puzzle is unlocked.\n",
                .{},
            ),
            .not_found => std.debug.print("That day does not exist for {d}.\n", .{year}),
            .internal_server_error => std.debug.print(
                "adventofcode.com had a problem; wait a moment and try again.\n",
                .{},
            ),
            else => {},
        }
        std.process.exit(1);
    }

    const body = response.written();
    if (body.len == 0) {
        std.debug.print("adventofcode.com returned an empty body\n", .{});
        std.process.exit(1);
    }
    if (std.mem.indexOfScalar(u8, body, '<') != null) {
        std.debug.print(
            "adventofcode.com returned HTML instead of puzzle input; the session is probably expired.\n",
            .{},
        );
        std.process.exit(1);
    }

    var path_buf: [64]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "inputs/day{d:0>2}.txt", .{day});

    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = body }) catch |err| {
        std.debug.print("cannot write {s}: {s}\n", .{ path, @errorName(err) });
        std.process.exit(1);
    };

    std.debug.print("saved {s} ({d} bytes)\n", .{ path, body.len });
}

fn resolveSession(init: std.process.Init, arena: std.mem.Allocator) ![]const u8 {
    if (init.environ_map.get("AOC_SESSION")) |session| {
        return std.mem.trim(u8, session, " \t\r\n");
    }

    const contents = try std.Io.Dir.cwd().readFileAlloc(
        init.io,
        ".aoc-session",
        arena,
        .limited(4096),
    );
    return std.mem.trim(u8, contents, " \t\r\n");
}

fn printUsage(io: std.Io) void {
    std.Io.File.stdout().writeStreamingAll(io, usage) catch {};
}
