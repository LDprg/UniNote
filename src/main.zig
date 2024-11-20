const std = @import("std");
const protobuf = @import("protobuf");

const c = @import("c.zig");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const cairo = @import("cairo.zig");

const test_pb = @import("proto/test.pb.zig");

const x = 640;
const y = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    window.init(x, y);
    defer window.deinit();

    // imgui
    imgui.init();
    defer imgui.deinit();

    // cairo init
    cairo.init();
    defer cairo.deinit();

    // protobuf
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

    var quit = false;

    while (!quit) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            if (e.type == c.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        cairo.update();
        imgui.update();

        c.igShowDemoWindow(null);

        window.draw(struct {
            fn f() void {
                cairo.draw();
                imgui.draw();
            }
        }.f);
    }
}
