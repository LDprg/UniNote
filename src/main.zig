const std = @import("std");

const c = @import("c.zig");

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
                event.event.quit => break :loop,
                event.event.mouseMotion => {
                    const cr = cairo.getNative();

                    c.cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
                    c.cairo_paint(cr);

                    c.cairo_set_source_rgb(cr, 0.0, 0.0, 1.0);
                    c.cairo_rectangle(cr, e.motion.x, e.motion.y, 200, 150);
                    c.cairo_fill(cr);
                },
                else => {},
            }
        }

        cairo.update();
        imgui.update();

        if (c.igBeginMainMenuBar()) {
            defer c.igEndMainMenuBar();

            if (c.igBeginMenu("File", true)) {
                defer c.igEndMenu();

                std.debug.print("Size: {}\n", .{@as(i32, @intFromFloat(c.igGetFrameHeight()))});

                if (c.igMenuItem_Bool("Save", "", false, true)) {
                    std.debug.print("Save\n", .{});
                }
                if (c.igMenuItem_Bool("Open", "", false, true)) {
                    std.debug.print("Open\n", .{});
                }
            }
        }

        c.igShowDemoWindow(null);

        window.clear();

        cairo.draw();
        imgui.draw();

        window.draw();
    }
}
