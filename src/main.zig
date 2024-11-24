const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const protobuf = @import("protobuf.zig");
const event = @import("event.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("Leaks deteced!");
    }

    const alloc = gpa.allocator();

    try window.init(alloc, 1280, 960);
    defer window.deinit();

    try imgui.init();
    defer imgui.deinit() catch std.debug.panic("Imgui deinit failed", .{});

    try protobuf.init(alloc);
    defer protobuf.deinit();

    std.debug.print("Staring Main Loop\n", .{});

    var x: f32 = 0;
    var y: f32 = 0;

    loop: while (true) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            switch (@as(event.event, @enumFromInt(e.type))) {
                event.event.quit => break :loop,
                event.event.mouseMotion, event.event.penMotion => {
                    x = e.motion.x;
                    y = e.motion.y;
                },
                else => {},
            }
        }

        imgui.update();

        if (c.igBeginMainMenuBar()) {
            defer c.igEndMainMenuBar();

            if (c.igBeginMenu("File", true)) {
                defer c.igEndMenu();

                // std.debug.print("Size: {}\n", .{@as(i32, @intFromFloat(c.igGetFrameHeight()))});

                if (c.igMenuItem_Bool("Save", "", false, true)) {
                    std.debug.print("Save\n", .{});
                }
                if (c.igMenuItem_Bool("Open", "", false, true)) {
                    std.debug.print("Open\n", .{});
                }
            }
        }

        c.igShowDemoWindow(null);

        try window.clear();

        try imgui.draw();

        try window.draw();
    }
}
