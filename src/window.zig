const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cDefine("CIMGUI_USE_SDL3", "TRUE");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "TRUE");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
    @cInclude("cimgui_impl_sdlrenderer3.h");
});

var sdl_window: ?*c.SDL_Window = undefined;

pub fn init(x: i32, y: i32) void {
    const sdL_init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (!sdL_init) {
        std.debug.print("Could not init SDL3: {s}\n", .{c.SDL_GetError()});
        return;
    }

    sdl_window = c.SDL_CreateWindow("UniNote", x, y, c.SDL_WINDOW_VULKAN);

    if (sdl_window == null) {
        std.debug.print("Could not create window: {s}\n", .{c.SDL_GetError()});
        return;
    }
}

pub fn deinit() void {
    c.SDL_DestroyWindow(sdl_window);
    c.SDL_Quit();
}

pub fn getNative() ?*c.SDL_Window {
    return sdl_window;
}
