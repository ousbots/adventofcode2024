const std = @import("std");

var alloc: ?std.mem.Allocator = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    alloc = arena.allocator();

    // const path: []const u8 = "inputs/day3/example_input1.txt";
    // const path: []const u8 = "inputs/day3/example_input2.txt";
    const path: []const u8 = "inputs/day3/input.txt";
    const data = try readData(path);

    try partOne(data);
    try partTwo(data);
}

// Parse a 'do()' instruction.
fn parseDo(line: []const u8, index: usize) !struct { found: bool, index: usize } {
    var new_index: usize = index;

    if (new_index + 3 >= line.len) {
        return .{ .found = false, .index = new_index };
    }

    if (line[new_index] != 'd') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != 'o') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != '(') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != ')') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    return .{ .found = true, .index = new_index };
}

// Parse a 'don't()' instruction.
fn parseDont(line: []const u8, index: usize) !struct { found: bool, index: usize } {
    var new_index: usize = index;

    if (new_index + 6 >= line.len) {
        return .{ .found = false, .index = new_index };
    }

    if (line[new_index] != 'd') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != 'o') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != 'n') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != '\'') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != 't') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != '(') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    if (line[new_index] != ')') {
        return .{ .found = false, .index = new_index };
    }
    new_index += 1;

    return .{ .found = true, .index = new_index };
}

// Parse a 'mul(x,y)' instruction.
fn parseMul(line: []const u8, index: usize) !struct { found: bool, index: usize, first: u32, second: u32 } {
    var new_index: usize = index;

    if (new_index + 3 >= line.len) {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }

    if (line[new_index] != 'm') {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }
    new_index += 1;

    if (line[new_index] != 'u') {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }
    new_index += 1;

    if (line[new_index] != 'l') {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }
    new_index += 1;

    if (line[new_index] != '(') {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }
    new_index += 1;

    const first_start: usize = new_index;
    while (new_index < line.len and std.ascii.isDigit(line[new_index])) {
        new_index += 1;
    }
    if (new_index >= line.len or line[new_index] != ',') {
        return .{ .found = false, .index = new_index, .first = 0, .second = 0 };
    }

    const first = try std.fmt.parseInt(u32, line[first_start..new_index], 10);

    new_index += 1;
    const second_start: usize = new_index;
    while (new_index < line.len - 1 and std.ascii.isDigit(line[new_index])) {
        new_index += 1;
    }
    if (new_index >= line.len or line[new_index] != ')') {
        return .{ .found = false, .index = new_index, .first = first, .second = 0 };
    }

    const second = try std.fmt.parseInt(u32, line[second_start..new_index], 10);
    new_index += 1;

    return .{ .found = true, .index = new_index, .first = first, .second = second };
}

// Calculate the number of safe reports.
fn partOne(data: [][]const u8) !void {
    var sum: u32 = 0;

    for (data) |line| {
        var index: usize = 0;

        while (index < line.len) {
            const results = try parseMul(line, index);

            if (results.index > index) {
                index = results.index;
            } else {
                index += 1;
            }

            if (results.found) {
                sum += results.first * results.second;
            }
        }
    }

    std.log.info("Final sum {d}", .{sum});
}

// Calculate the number of safe reports with a problem dampening of one.
fn partTwo(data: [][]const u8) !void {
    var sum: u32 = 0;
    var active: bool = true;

    for (data) |line| {
        var index: usize = 0;

        while (index < line.len) {
            const mult = try parseMul(line, index);
            if (mult.found) {
                if (active) {
                    sum += mult.first * mult.second;
                }
                index = mult.index;
                continue;
            }

            const do = try parseDo(line, index);
            if (do.found) {
                active = true;
                index = do.index;
                continue;
            }

            const dont = try parseDont(line, index);
            if (dont.found) {
                active = false;
                index = dont.index;
                continue;
            }

            index += 1;
        }
    }

    std.log.info("Final activated sum {d}", .{sum});
}

// readData reads the path and parses it into an array that needs to be freed by the caller.
fn readData(path: []const u8) ![][]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.reader().readAllAlloc(alloc.?, file_size);
    defer alloc.?.free(content);

    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var result = std.ArrayList([]const u8).init(alloc.?);

    while (lines.next()) |line| {
        var copy = std.ArrayList(u8).init(alloc.?);
        for (line) |char| {
            try copy.append(char);
        }
        try result.append(try copy.toOwnedSlice());
    }

    return result.toOwnedSlice();
}
