const std = @import("std");

const vulkan = @import("vulkan.zig");

const c = @import("c.zig");

var sdl_window: ?*c.SDL_Window = undefined;
pub var surface: c.VkSurfaceKHR = undefined;
pub var extensions: []?[*]const u8 = undefined;

pub const size = struct { x: i32, y: i32 };
pub const event = enum(u32) { quit = c.SDL_EVENT_QUIT };

pub fn init(alloc: std.mem.Allocator, x: i32, y: i32) !void {
    // _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "wayland,x11");

    std.debug.print("Init SDL\n", .{});

    const sdL_init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (!sdL_init) {
        std.debug.print("Could not init SDL3: {s}\n", .{c.SDL_GetError()});
        return;
    }

    std.debug.print("Init Window\n", .{});

    sdl_window = c.SDL_CreateWindow("UniNote", x, y, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIGH_PIXEL_DENSITY);

    if (sdl_window == null) {
        std.debug.print("Could not create window: {s}\n", .{c.SDL_GetError()});
        return;
    }

    var extensions_count: u32 = 0;
    _ = c.SDL_Vulkan_GetInstanceExtensions(&extensions_count);
    extensions = @constCast(c.SDL_Vulkan_GetInstanceExtensions(&extensions_count)[0..extensions_count]);

    try vulkan.init(alloc);

    // Create Window Surface
    const surface_init = c.SDL_Vulkan_CreateSurface(sdl_window, vulkan.g_Instance, vulkan.g_Allocator, &surface);
    if (!surface_init) {
        std.debug.panic("Failed to create Vulkan surface.\n", .{});
    }
}

pub fn deinit() void {
    c.SDL_Vulkan_DestroySurface(vulkan.g_Instance, surface, vulkan.g_Allocator);
    vulkan.deinit();

    c.SDL_DestroyWindow(sdl_window);
    c.SDL_Quit();
}

pub fn getNativeWindow() ?*c.SDL_Window {
    return sdl_window;
}

pub fn getEvent() ?c.SDL_Event {
    var e: c.SDL_Event = undefined;

    if (c.SDL_PollEvent(&e))
        return e;

    return null;
}

pub fn showWindow() void {
    _ = c.SDL_ShowWindow(sdl_window);
}

pub fn getSize() size {
    var x: i32 = 0;
    var y: i32 = 0;

    _ = c.SDL_GetWindowSize(sdl_window, @ptrCast(&x), @ptrCast(&y));

    return .{ .x = x, .y = y };
}

pub fn getWindowTitle() [*]const u8 {
    return c.SDL_GetWindowTitle(sdl_window);
}

pub fn draw() void {}
