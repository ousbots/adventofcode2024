const std = @import("std");

var alloc: ?std.mem.Allocator = undefined;

pub fn main() !void {
    // Use an arena allocator for convenience.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    alloc = arena.allocator();

    // const example_path = "./inputs/day1/example_input.txt";
    const path = "./inputs/day1/input.txt";
    const data = try readInput(path);

    try partOne(data);
    try partTwo(data);
}

// partOne calculates the sum of differences between the smallest values in each list.
fn partOne(data: [][2]u32) !void {
    var first = std.ArrayList(u32).init(alloc.?);
    var second = std.ArrayList(u32).init(alloc.?);

    for (data) |elements| {
        try first.append(elements[0]);
        try second.append(elements[1]);
    }

    std.mem.sort(u32, first.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, second.items, {}, std.sort.asc(u32));

    var sum: u32 = 0;
    for (0..first.items.len) |i| {
        if (first.items[i] > second.items[i]) {
            sum += first.items[i] - second.items[i];
        } else {
            sum += second.items[i] - first.items[i];
        }
    }

    std.log.info("Total difference: {d}", .{sum});
}

// partTwo calculates a similarity score of the lists of numbers.
// The score is the sum of first list values multiplied by their number of occurances in the second.
fn partTwo(data: [][2]u32) !void {
    var score: u32 = 0;

    var first = std.ArrayList(u32).init(alloc.?);
    var second = std.ArrayList(u32).init(alloc.?);

    for (data) |elements| {
        try first.append(elements[0]);
        try second.append(elements[1]);
    }

    std.mem.sort(u32, first.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, second.items, {}, std.sort.asc(u32));

    var secondi: usize = 0;
    for (first.items) |val| {
        if (secondi >= second.items.len) {
            break;
        }

        while (second.items[secondi] < val and secondi < second.items.len - 1) {
            secondi += 1;
        }

        var factor: u32 = 0;
        while (second.items[secondi] == val and secondi < second.items.len) {
            factor += 1;
            secondi += 1;
        }

        score += val * factor;
    }

    std.log.info("The similarity score {d}", .{score});
}

// readInput reads the path and parses it into an array that needs to be freed by the caller.
fn readInput(path: []const u8) ![][2]u32 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.reader().readAllAlloc(alloc.?, file_size);
    defer alloc.?.free(content);

    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var result = std.ArrayList([2]u32).init(alloc.?);

    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeAny(u8, std.mem.trim(u8, line, " \t"), " \t");

        const first_str = tokens.next().?;
        const second_str = tokens.next().?;

        const first = try std.fmt.parseInt(u32, first_str, 10);
        const second = try std.fmt.parseInt(u32, second_str, 10);

        try result.append(.{ first, second });
    }

    return try result.toOwnedSlice();
}
