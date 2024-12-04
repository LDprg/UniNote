const std = @import("std");

pub const c = @import("c.zig");
pub const event = @import("core/event.zig");
pub const imgui = @import("renderer/imgui.zig");
pub const protobuf = @import("file/protobuf.zig");
pub const vulkan = @import("renderer/vulkan.zig");
pub const window = @import("core/window.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) std.debug.panic("Leaks deteced!", .{});
    }

    const alloc = gpa.allocator();

    try window.init(1280, 960);
    defer window.deinit();

    try vulkan.init(alloc);
    defer vulkan.deinit();

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
                event.event.mouse_motion, event.event.pen_motion => {
                    x = e.motion.x;
                    y = e.motion.y;

                    // const size = window.getSize();
                    // vulkan.vertexBuffer.vertices[0].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 1;
                    // vulkan.vertexBuffer.vertices[0].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 1;

                    // vulkan.vertexBuffer.vertices[1].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 0.5;
                    // vulkan.vertexBuffer.vertices[1].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 0;

                    // vulkan.vertexBuffer.vertices[2].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 1.5;
                    // vulkan.vertexBuffer.vertices[2].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 0;

                    // try vulkan.vertexBuffer.createVertexBuffer();
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
                    std.debug.print("Save: {}\n", .{vulkan.swapchain.extent});
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
