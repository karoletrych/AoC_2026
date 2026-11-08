# Advent of Code 2026 (Zig)

Solutions for [Advent of Code 2026](https://adventofcode.com/2026) written in Zig.

All 25 days are wired up. Days 1–3 currently contain ports of the 2025
solutions and will be replaced when the 2026 puzzles start.

## Requirements

* [Zig](https://ziglang.org/) 0.17.0

## Usage

```bash
# run both parts of a day
zig build run -- 1

# run a single part
zig build run -- 1 2

# run tests
zig build test

# download a puzzle input (see below)
zig build pull -- 1

# build only
zig build
```

The runner reads `inputs/dayNN.txt`, then prints each part's answer and its
runtime. Days without an implementation report `error.NotImplemented`.
For long-running days add `-Doptimize=ReleaseFast` before `--`.

## Puzzle inputs

Advent of Code asks participants not to publish their puzzle inputs, so
`inputs/` is git-ignored. Inputs are stored as `inputs/dayNN.txt`.

### Downloading inputs

`zig build pull` uses your `session` cookie from a logged-in adventofcode.com
session. Provide it either through the `AOC_SESSION` environment variable or in
a `.aoc-session` file at the repository root (both are git-ignored):

```bash
# bash
export AOC_SESSION=your-session-cookie
# PowerShell
$env:AOC_SESSION = "your-session-cookie"
```

Then:

```bash
zig build pull -- 1       # 2026 input -> inputs/day01.txt
zig build pull -- 1 2025  # older puzzle  -> inputs/day01.txt
```

The tool refuses HTML responses, so an expired session fails loudly instead of
saving the login page as your input.

## Layout

```
.
├── build.zig              # build graph: run + test steps
├── build.zig.zon
├── inputs/                # your puzzle inputs (git-ignored)
└── src/
    ├── main.zig           # CLI runner
    ├── days.zig           # registry of all days
    ├── util.zig           # input loading, line iterator, helper re-exports
    ├── util/
    │   ├── grid.zig       # 2D grid
    │   ├── vec.zig        # integer 3D vector
    │   └── combinatorics.zig  # permutations
    └── days/
        ├── day01.zig
        ├── day02.zig
        └── ...            # day25.zig
```

## Implementing a day

Each module in `src/days/` exposes:

```zig
pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64
pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64
```

`input` is the whole file contents and `allocator` is the runner's arena, so
allocations live until the process exits. Return the answer as an integer, or
any error. Add `test` blocks next to the implementation so `zig build test`
covers it.

## Helpers

Ported from the 2025 C# repository, keeping only what makes sense in Zig.

### Grid

```zig
const util = @import("../util.zig");

var grid = try util.fromLines(allocator, input); // util.Grid(u8), LF or CRLF
defer grid.deinit();

const start = grid.find('S') orelse return error.NoStart;
grid.set(start.x, start.y, '.');

// get() takes signed coordinates and returns null out of bounds
const start_x: isize = @intCast(start.x);
const start_y: isize = @intCast(start.y);
if (grid.get(start_x - 1, start_y)) |cell| {
    _ = cell;
}

for (grid.row(0)) |cell| {
    _ = cell;
}

const column = try grid.column(allocator, 0);
defer allocator.free(column);

var rotated = try grid.transpose(allocator);
defer rotated.deinit();

std.debug.print("{f}", .{grid}); // u8 grids print as characters
```

`util.Grid(T)` also has `init`, `initFilled`, `at`, `inBounds`, `width` and
`height`. The C# helpers `HasIndex`, `GetRow`, `GetColumn`, `FindItem` and
`Transpose` map to `inBounds`, `row`, `column`, `find` and `transpose`.

### Vec3

```zig
const a = util.Vec3.init(1, 2, 3);
const b = util.Vec3.init(4, 6, 3);

const moved = util.Vec3.add(a, b);
const delta = util.Vec3.sub(a, b);
const scaled = util.Vec3.scale(a, 2);
const steps = util.Vec3.manhattan(a, b); // u64
const dist = util.Vec3.distance(a, b);   // f64

// plain structs hash by value, no custom hasher needed
var seen = std.AutoHashMap(util.Vec3, void).init(allocator);
defer seen.deinit();
try seen.put(a, {});
```

### Permutations

```zig
var permutations = try util.Permutations(u8).init(allocator, &[_]u8{ 1, 2, 3 });
defer permutations.deinit();

while (permutations.next()) |perm| {
    _ = perm; // []const u8, reused between iterations
}
```

### Lines

```zig
var lines = util.Lines.init(input); // strips trailing '\r'
while (lines.next()) |line| {
    _ = line;
}
```

### Not ported

The C#-specific conversions (`ToMatrix`, `To2DArray`), `ToBinaryString` (use
`std.fmt`) and the input-path plumbing were dropped: Zig's stdlib or the runner
already covers them.
