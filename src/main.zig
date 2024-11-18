const std = @import("std");

const sdl = @import("sdl/sdl3.zig");
const cairo = @import("cairo/cairo.zig");

pub fn main() !void {
    const init = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    if (!init) {
        std.debug.print("Could not init SDL3: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    const window: ?*sdl.SDL_Window = sdl.SDL_CreateWindow("UniNote", 640, 480, sdl.SDL_WINDOW_VULKAN);
    defer sdl.SDL_DestroyWindow(window);

    if (window == null) {
        std.debug.print("Could not create window: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    var quit = false;

    while (!quit) {
        var e: ?sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e.?)) {
            if (e.?.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            }
        }
    }
}
