const std = @import("std");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const cairo = @import("cairo.zig");
const protobuf = @import("protobuf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    window.init(1280, 960);
    defer window.deinit();

    // imgui
    imgui.init();
    defer imgui.deinit();

    // cairo init
    cairo.init();
    defer cairo.deinit();

    // protobuf
    try protobuf.init(alloc);
    defer protobuf.deinit();

    loop: while (true) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            if (e.type == @intFromEnum(window.event.quit)) {
                break :loop;
            }
        }

        cairo.update();
        imgui.update();

        imgui.showDemoWindow(null);

        window.clear();

        cairo.draw();
        imgui.draw();

        window.draw();
    }
}
