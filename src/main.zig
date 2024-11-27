const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");
const imgui = @import("imgui.zig");
const protobuf = @import("protobuf.zig");
const event = @import("event.zig");

const vulkan = @import("vulkan.zig");

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

                    const size = window.getSize();
                    vulkan.vertexBuffer.vertices[0].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 1;
                    vulkan.vertexBuffer.vertices[0].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 1;

                    vulkan.vertexBuffer.vertices[1].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 0.5;
                    vulkan.vertexBuffer.vertices[1].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 0;

                    vulkan.vertexBuffer.vertices[2].pos[0] = (2 * x / @as(f32, @floatFromInt(size.x))) - 1.5;
                    vulkan.vertexBuffer.vertices[2].pos[1] = (2 * y / @as(f32, @floatFromInt(size.y))) - 0;

                    const bufferInfo = c.VkBufferCreateInfo{
                        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
                        .size = @sizeOf(vulkan.vertexBuffer.Vertex) * vulkan.vertexBuffer.vertices.len,
                        .usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                    };
                    var data: ?*anyopaque = null;
                    try vulkan.util.check_vk(c.vkMapMemory(vulkan.device.device, vulkan.vertexBuffer.vertexBufferMemory, 0, bufferInfo.size, 0, @ptrCast(&data)));
                    @memcpy(@as([*]vulkan.vertexBuffer.Vertex, @ptrCast(@alignCast(data))), vulkan.vertexBuffer.vertices);
                    c.vkUnmapMemory(vulkan.device.device, vulkan.vertexBuffer.vertexBufferMemory);
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
                    std.debug.print("Save: {}\n", .{vulkan.swapChain.extent});
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
