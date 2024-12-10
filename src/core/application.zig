//! Contains basic loop
//! Mainly exists to keep app.zig cleaner

const std = @import("std");

const c = @import("root").c;

const app = @import("root").app;

const window = @import("root").core.window;

const protobuf = @import("root").file.protobuf;

const imgui = @import("root").renderer.imgui;
const vulkan = @import("root").renderer.vulkan;

var is_running = true;

pub fn run(alloc: std.mem.Allocator) !void {
    try window.init(1280, 960);
    defer window.deinit();

    try vulkan.init(alloc);
    defer vulkan.deinit();

    try imgui.init();
    defer imgui.deinit();

    try protobuf.init(alloc);
    defer protobuf.deinit();

    try app.init(alloc);
    defer app.deinit();

    std.log.info("Staring Main Loop", .{});

    while (is_running) {
        while (window.getEvent()) |e| {
            imgui.processEvent(&e);

            if (e.type != c.SDL_EVENT_MOUSE_BUTTON_UP and
                e.type != c.SDL_EVENT_MOUSE_BUTTON_DOWN and
                e.type != c.SDL_EVENT_MOUSE_WHEEL or
                !c.igGetIO().*.WantCaptureMouse)
            {
                try app.processEvent(&e);
            }
        }

        imgui.update();
        try app.update();

        if (!vulkan.swapchain_rebuild) {
            try vulkan.clear();
        }

        try app.draw();
        try imgui.draw();

        if (!vulkan.swapchain_rebuild) {
            try vulkan.draw();
        } else {
            try vulkan.rebuildSwapChain();
        }
    }
}

pub fn close() void {
    is_running = false;
}
