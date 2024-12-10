const std = @import("std");

const c = @import("root").c;

const vulkan = @import("root").renderer.vulkan;

pub var window: ?*c.SDL_Window = undefined;

pub const size = struct { x: u32, y: u32 };
pub const event = enum(u32) { quit = c.SDL_EVENT_QUIT };

pub fn init(x: i32, y: i32) !void {
    std.log.info("Init window with x: {}, y: {}", .{ x, y });

    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "wayland,x11");

    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (!sdl_init) {
        std.log.err("Could not init SDL3: {s}", .{c.SDL_GetError()});
        return;
    }

    window = c.SDL_CreateWindow(
        "UniNote",
        x,
        y,
        c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIGH_PIXEL_DENSITY,
    );

    if (window == null) {
        std.log.err("Could not create window: {s}", .{c.SDL_GetError()});
        return;
    }
}

pub fn deinit() void {
    std.log.info("Deinit window", .{});

    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
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

pub fn getSize() size {
    var x: u32 = 0;
    var y: u32 = 0;

    _ = c.SDL_GetWindowSize(window, @ptrCast(&x), @ptrCast(&y));

    return .{ .x = x, .y = y };
}
