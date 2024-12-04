const std = @import("std");

const c = @import("root").c;

const event = @import("root").core.event;
const window = @import("root").core.window;
const application = @import("root").core.application;

const protobuf = @import("root").file.protobuf;

const imgui = @import("root").renderer.imgui;
const vulkan = @import("root").renderer.vulkan;

var x: f32 = 0;
var y: f32 = 0;

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;
}

pub fn deinit() void {}

pub fn processEvent(e: c.SDL_Event) !void {
    switch (@as(event.event, @enumFromInt(e.type))) {
        event.event.quit => application.close(),
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

pub fn draw() !void {}
