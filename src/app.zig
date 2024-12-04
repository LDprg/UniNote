const std = @import("std");

const c = @import("root").c;

const event = @import("root").core.event;
const window = @import("root").core.window;
const application = @import("root").core.application;

const protobuf = @import("root").file.protobuf;

const imgui = @import("root").renderer.imgui;
const vulkan = @import("root").renderer.vulkan;
const shape = @import("root").renderer.shape;

var x: f32 = 0;
var y: f32 = 0;

var alloc: std.mem.Allocator = undefined;

var test_shape: shape.ShapeIndexed = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    var vertex = [_]vulkan.vertex_buffer.Vertex{
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 200 }, .color = [4]f32{ 1, 0, 0, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 200 }, .color = [4]f32{ 0, 1, 0, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 700 }, .color = [4]f32{ 0, 0, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 700 }, .color = [4]f32{ 1, 0, 1, 1 } },
    };
    var index = [_]u16{ 0, 1, 2, 2, 3, 0 };
    try test_shape.init(&vertex, &index);
}

pub fn deinit() void {
    test_shape.deinit();
}

pub fn processEvent(e: *const c.SDL_Event) !void {
    switch (@as(event.Event, @enumFromInt(e.type))) {
        event.Event.quit => application.close(),
        event.Event.mouse_motion, event.Event.pen_motion => {
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

pub fn update() !void {
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
}

pub fn draw() !void {
    test_shape.draw();
}
