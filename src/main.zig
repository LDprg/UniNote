const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const protobuf = @import("protobuf.zig");
const event = @import("event.zig");
const skia = @import("skia.zig");

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

    try skia.init();
    defer skia.deinit();

    try protobuf.init(alloc);
    defer protobuf.deinit();

    loop: while (true) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            switch (@as(event.event, @enumFromInt(e.type))) {
                event.event.quit => break :loop,
                event.event.mouseMotion => {},
                else => {},
            }
        }

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

        skia.draw();
        imgui.draw();

        window.draw();
    }
}
