const std = @import("std");

const protobuf = @import("protobuf");

const test_pb = @import("proto/test.pb.zig");

pub fn init(alloc: std.mem.Allocator) !void {
    std.log.info("Init protobuf", .{});

    const file = try std.fs.cwd().createFile(
        "test.bin",
        .{ .read = true },
    );
    defer file.close();

    var test_person = test_pb.Person.init(alloc);
    defer test_person.deinit();

    test_person.name = protobuf.ManagedString.static("test123");
    test_person.id = 0xFF;

    const data = try test_person.encode(alloc);
    defer alloc.free(data);

    _ = try file.writeAll(data);

    // compression
    const file2 = try std.fs.cwd().createFile(
        "test.bin.lz",
        .{ .read = true },
    );
    defer file2.close();

    var comp = try std.compress.zlib.compressor(file2.writer(), .{});
    _ = try comp.write(data);
    try comp.finish();
}

pub fn deinit() void {
    std.log.info("Deinit protobuf", .{});
}
