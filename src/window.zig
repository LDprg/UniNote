const std = @import("std");

const vulkan = @import("vulkan.zig");

const c = @import("c.zig");

var window: ?*c.SDL_Window = undefined;

pub const size = struct { x: u32, y: u32 };
pub const event = enum(u32) { quit = c.SDL_EVENT_QUIT };

pub fn init(x: i32, y: i32) !void {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "wayland,x11");

    std.debug.print("Init SDL\n", .{});

    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (!sdl_init) {
        std.debug.print("Could not init SDL3: {s}\n", .{c.SDL_GetError()});
        return;
    }

    std.debug.print("Init Window\n", .{});

    window = c.SDL_CreateWindow("UniNote", x, y, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIGH_PIXEL_DENSITY);

    if (window == null) {
        std.debug.print("Could not create window: {s}\n", .{c.SDL_GetError()});
        return;
    }
}

pub fn deinit() void {
    std.debug.print("Deinit sdl\n", .{});

    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}

pub fn getNativeWindow() ?*c.SDL_Window {
    return window;
}

pub fn getEvent() ?c.SDL_Event {
    var e: c.SDL_Event = undefined;

    if (c.SDL_PollEvent(&e)) {
        if (e.type == c.SDL_EVENT_WINDOW_RESIZED) {
            vulkan.swapchain_rebuild = true;
        }
        return e;
    }

    return null;
}

pub fn showWindow() void {
    _ = c.SDL_ShowWindow(window);
}

pub fn getSize() size {
    var x: u32 = 0;
    var y: u32 = 0;

    _ = c.SDL_GetWindowSize(window, @ptrCast(&x), @ptrCast(&y));

    return .{ .x = x, .y = y };
}

pub fn getWindowTitle() [*]const u8 {
    return c.SDL_GetWindowTitle(window);
}

pub fn clear() !void {
    if (!vulkan.swapchain_rebuild) {
        try vulkan.clear();
    }
}

pub fn draw() !void {
    if (!vulkan.swapchain_rebuild) {
        try vulkan.draw();
    } else {
        try vulkan.rebuildSwapChain();
    }
}
