const std = @import("std");

var alloc: ?std.mem.Allocator = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    alloc = arena.allocator();

    // const path: []const u8 = "inputs/day2/example_input.txt";
    const path: []const u8 = "inputs/day2/input.txt";
    const data = try readData(path);

    try partOne(data);
    try partTwo(data);
}

// Checks if a report is safe.
// NOTE: A safe report has level differences between one and three and the level differences are
// always in the same direction.
fn isSafe(report: []u16) bool {
    for (0..report.len - 1) |index| {
        if (index + 1 < report.len) {
            const diff = @as(i32, report[index + 1]) - @as(i32, report[index]);

            if (@abs(diff) < 1 or @abs(diff) > 3) {
                return false;
            }

            if (index > 0) {
                const prev_diff = @as(i32, report[index]) - @as(i32, report[index - 1]);
                if ((prev_diff < 0 and diff > 0) or (prev_diff > 0 and diff < 0)) {
                    return false;
                }
            }
        }
    }

    return true;
}

// Calculate the number of safe reports.
fn partOne(data: [][]u16) !void {
    var safe_count: u16 = 0;
    for (data) |report| {
        if (isSafe(report)) {
            safe_count += 1;
        }
    }

    std.log.info("Found {} safe reports", .{safe_count});
}

// Calculate the number of safe reports with a problem dampening of one.
fn partTwo(data: [][]u16) !void {
    var safe_count: u16 = 0;
    report_loop: for (data) |report| {
        var temp_report: []u16 = try alloc.?.alloc(u16, report.len - 1);
        for (0..report.len) |skip| {
            var copy_index: usize = 0;
            for (0..report.len) |index| {
                if (index == skip) {
                    continue;
                }

                temp_report[copy_index] = report[index];
                copy_index += 1;
            }

            if (isSafe(temp_report)) {
                safe_count += 1;
                continue :report_loop;
            } else {}
        }
    }

    std.log.info("Found {} safe reports", .{safe_count});
}

// readData reads the path and parses it into an array that needs to be freed by the caller.
fn readData(path: []const u8) ![][]u16 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try file.reader().readAllAlloc(alloc.?, file_size);
    defer alloc.?.free(content);

    var lines = std.mem.tokenizeScalar(u8, content, '\n');
    var result = std.ArrayList([]u16).init(alloc.?);

    while (lines.next()) |line| {
        var values = std.ArrayList(u16).init(alloc.?);

        var tokens = std.mem.tokenizeAny(u8, std.mem.trim(u8, line, " \t"), " \t");
        while (tokens.next()) |token| {
            try values.append(try std.fmt.parseInt(u16, token, 10));
        }

        try result.append(try values.toOwnedSlice());
    }

    return result.toOwnedSlice();
}

// Convert a report to a printable string.
fn toString(report: []u16) ![]u8 {
    var result = std.ArrayList(u8).init(alloc.?);

    try result.append('[');
    for (report, 0..) |value, index| {
        if (index > 0 and index < report.len) {
            try result.append(',');
            try result.append(' ');
        }

        try std.fmt.formatInt(value, 10, std.fmt.Case.lower, .{}, result.writer());
    }
    try result.append(']');

    return result.toOwnedSlice();
}
