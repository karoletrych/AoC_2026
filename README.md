# Advent of Code 2026 (Zig)

Solutions for [Advent of Code 2026](https://adventofcode.com/2026) written in Zig.

This is a fresh scaffold: all 25 days are wired up but not solved yet.

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

# build only
zig build
```

The runner reads `inputs/dayNN.txt`, then prints each part's answer and its
runtime. Days without an implementation report `error.NotImplemented`.

## Puzzle inputs

Advent of Code asks participants not to publish their puzzle inputs, so
`inputs/` is git-ignored. To run a day, save your own input there:

```
inputs/day01.txt
inputs/day02.txt
...
```

## Layout

```
.
├── build.zig          # build graph: run + test steps
├── build.zig.zon
├── inputs/            # your puzzle inputs (git-ignored)
└── src/
    ├── main.zig       # CLI runner
    ├── days.zig       # registry of all days
    ├── util.zig       # input reading and line iterator
    └── days/
        ├── day01.zig
        ├── day02.zig
        └── ...        # day25.zig
```

## Implementing a day

Each module in `src/days/` exposes:

```zig
pub fn part1(input: []const u8) !i64
pub fn part2(input: []const u8) !i64
```

`input` is the whole file contents. Return the answer as an integer, or any
error. Add `test` blocks next to the implementation so `zig build test` covers
it; tests can import `util.Lines` for line-by-line parsing.
