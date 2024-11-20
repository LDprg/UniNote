const std = @import("std");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const cairo = @import("cairo.zig");
const protobuf = @import("protobuf.zig");
const event = @import("event.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("Leaks deteced!");
    }

    const alloc = gpa.allocator();

    try window.init(1280, 960);
    defer window.deinit();

    try imgui.init();
    defer imgui.deinit();

    try cairo.init();
    defer cairo.deinit();

    try protobuf.init(alloc);
    defer protobuf.deinit();

    loop: while (true) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            switch (@as(event.event, @enumFromInt(e.type))) {
                .quit => break :loop,
                else => {},
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
