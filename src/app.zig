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
var test_shape2: shape.Shape = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    var vertex_shape = [_]vulkan.vertex_buffer.Vertex{
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 200 }, .color = [4]f32{ 1, 0, 0, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 200 }, .color = [4]f32{ 0, 1, 0, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 700 }, .color = [4]f32{ 0, 0, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 700 }, .color = [4]f32{ 1, 0, 1, 1 } },
    };
    var index_shape = [_]u16{ 0, 1, 2, 2, 3, 0 };
    try test_shape.init(&vertex_shape, &index_shape);

    var vertex_shape2 = [_]vulkan.vertex_buffer.Vertex{
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 200 }, .color = [4]f32{ 1, 1, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 200 }, .color = [4]f32{ 1, 1, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 700 }, .color = [4]f32{ 1, 1, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 700, 700 }, .color = [4]f32{ 1, 1, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 700 }, .color = [4]f32{ 1, 1, 1, 1 } },
        vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 200, 200 }, .color = [4]f32{ 1, 1, 1, 1 } },
    };
    try test_shape2.init(&vertex_shape2);
}

pub fn deinit() void {
    test_shape.deinit();
    test_shape2.deinit();
}

pub fn processEvent(e: *const c.SDL_Event) !void {
    switch (@as(event.Event, @enumFromInt(e.type))) {
        event.Event.quit => application.close(),
        event.Event.mouse_motion, event.Event.pen_motion => {
            x = e.motion.x;
            y = e.motion.y;

            test_shape2.deinit();
            var vertex_shape2 = [_]vulkan.vertex_buffer.Vertex{
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 0, 0 }, .color = [4]f32{ 1, 1, 1, 1 } },
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 500, 0 }, .color = [4]f32{ 1, 1, 1, 1 } },
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 500, 500 }, .color = [4]f32{ 1, 1, 1, 1 } },
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 500, 500 }, .color = [4]f32{ 1, 1, 1, 1 } },
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 0, 500 }, .color = [4]f32{ 1, 1, 1, 1 } },
                vulkan.vertex_buffer.Vertex{ .pos = [2]f32{ 0, 0 }, .color = [4]f32{ 1, 1, 1, 1 } },
            };

            for (&vertex_shape2) |*vertex| {
                vertex.pos[0] += x;
                vertex.pos[1] += y;
            }

            try test_shape2.init(&vertex_shape2);
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
    test_shape2.draw();
}
