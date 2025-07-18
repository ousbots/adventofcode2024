const std = @import("std");

var alloc: ?std.mem.Allocator = undefined;

const Direction = enum {
    up,
    right,
    down,
    left,
    upright,
    downright,
    downleft,
    upleft,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    alloc = arena.allocator();

    // const path: []const u8 = "inputs/day4/example_input.txt";
    const path: []const u8 = "inputs/day4/input.txt";
    const data = try readData(path);

    partOne(data);
    partTwo(data);
}

// Compile a list of directions that contain "MAS" centered on the 'A'.
fn findMAS(data: [][]const u8, x: usize, y: usize) ![]Direction {
    var results = std.ArrayList(Direction).init(alloc.?);

    for (std.enums.values(Direction)) |direction| {
        if (getNeighbor(data, x, y, direction)) |val| {
            if (val == 'M') {
                if (getNeighbor(data, x, y, opposite(direction))) |oppval| {
                    if (oppval == 'S') {
                        try results.append(direction);
                    }
                }
            }
        }
    }

    return results.toOwnedSlice();
}

// Search the data for "XMAS" at the specified starting position and direction.
fn findXMAS(data: [][]const u8, x: usize, y: usize, direction: Direction) bool {
    const match = "XMAS";

    var x_pos: i64 = @intCast(x);
    var y_pos: i64 = @intCast(y);

    var x_delta: i8 = 0;
    var y_delta: i8 = 0;
    var i_match: usize = 0;

    switch (direction) {
        .up => {
            x_delta = 0;
            y_delta = -1;
        },
        .upright => {
            x_delta = 1;
            y_delta = -1;
        },
        .right => {
            x_delta = 1;
            y_delta = 0;
        },
        .downright => {
            x_delta = 1;
            y_delta = 1;
        },
        .down => {
            x_delta = 0;
            y_delta = 1;
        },
        .downleft => {
            x_delta = -1;
            y_delta = 1;
        },
        .left => {
            x_delta = -1;
            y_delta = 0;
        },
        .upleft => {
            x_delta = -1;
            y_delta = -1;
        },
    }

    while (i_match < match.len and x_pos < data.len and x_pos >= 0 and y_pos < data[x].len and y_pos >= 0) {
        const x_check: usize = @intCast(x_pos);
        const y_check: usize = @intCast(y_pos);

        if (data[y_check][x_check] != match[i_match]) {
            return false;
        }

        x_pos += x_delta;
        y_pos += y_delta;
        i_match += 1;
    }

    if (i_match == match.len) {
        return true;
    }

    return false;
}

// Convenience function to get a neighboring value in a specific direction.
fn getNeighbor(data: [][]const u8, x: usize, y: usize, direction: Direction) ?u8 {
    if (x < 0 or y < 0 or x > data.len or y > data[x].len) return null;

    return switch (direction) {
        .up => if (y > 0) data[y - 1][x] else null,
        .upright => if (y > 0 and x + 1 < data[y - 1].len) data[y - 1][x + 1] else null,
        .right => if (x + 1 < data[y].len) data[y][x + 1] else null,
        .downright => if (y + 1 < data.len and x + 1 < data[y + 1].len) data[y + 1][x + 1] else null,
        .down => if (y + 1 < data.len) data[y + 1][x] else null,
        .downleft => if (y + 1 < data.len and x > 0) data[y + 1][x - 1] else null,
        .left => if (x > 0) data[y][x - 1] else null,
        .upleft => if (y > 0 and x > 0) data[y - 1][x - 1] else null,
    };
}

// Check if a set of directions for an X cross.
fn isCross(directions: []Direction) bool {
    for (0..directions.len) |index| {
        if (!isDiagonal(directions[index])) continue;

        for (index + 1..directions.len) |check| {
            if (rotated(directions[index]) == directions[check] or rotated(opposite(directions[index])) == directions[check]) {
                return true;
            }
        }
    }

    return false;
}

// Check if a direction is a diagonal.
fn isDiagonal(direction: Direction) bool {
    return switch (direction) {
        .up => false,
        .upright => true,
        .right => false,
        .downright => true,
        .down => false,
        .downleft => true,
        .left => false,
        .upleft => true,
    };
}

// Return the opposite direction.
fn opposite(direction: Direction) Direction {
    return switch (direction) {
        .up => .down,
        .upright => .downleft,
        .right => .left,
        .downright => .upleft,
        .down => .up,
        .downleft => .upright,
        .left => .right,
        .upleft => .downright,
    };
}

// Count the number of times the work "XMAS" appears in any direction.
fn partOne(data: [][]const u8) void {
    var found: usize = 0;

    for (0..data.len) |y| {
        for (0..data[y].len) |x| {
            if (data[y][x] == 'X') {
                if (findXMAS(data, x, y, .up)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .upright)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .right)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .downright)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .down)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .downleft)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .left)) {
                    found += 1;
                }
                if (findXMAS(data, x, y, .upleft)) {
                    found += 1;
                }
            }
        }
    }

    std.log.info("Found {} instances of XMAS", .{found});
}

// Count the number of times that two strings "MAS" form a X centered on the "A".
fn partTwo(data: [][]const u8) void {
    var found: u16 = 0;

    for (0..data.len) |y| {
        for (0..data.len) |x| {
            if (data[y][x] == 'A') {
                if (isCross(findMAS(data, x, y) catch continue)) {
                    found += 1;
                }
            }
        }
    }

    std.log.info("Found {} instances of X-MAS", .{found});
}

fn readData(path: []const u8) ![][]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.reader().readAllAlloc(alloc.?, file_size);
    defer alloc.?.free(content);

    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var results = std.ArrayList([]const u8).init(alloc.?);

    while (lines.next()) |line| {
        const row = try alloc.?.alloc(u8, line.len);
        for (line, 0..) |char, index| {
            row[index] = char;
        }
        try results.append(row);
    }

    return results.toOwnedSlice();
}

// Return the direction rotated 90 degrees.
fn rotated(direction: Direction) Direction {
    return switch (direction) {
        .up => .right,
        .upright => .downright,
        .right => .down,
        .downright => .downleft,
        .down => .left,
        .downleft => .upleft,
        .left => .up,
        .upleft => .upright,
    };
}
