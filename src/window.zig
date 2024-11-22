const std = @import("std");

const c = @import("c.zig");

var sdl_window: ?*c.SDL_Window = undefined;

var gl_context: ?*c.SDL_GLContextState = undefined;

pub const size = struct { x: i32, y: i32 };
pub const event = enum(u32) { quit = c.SDL_EVENT_QUIT };

pub fn init(x: i32, y: i32) !void {
    _ = c.SDL_SetHint(c.SDL_HINT_VIDEO_DRIVER, "wayland,x11");

    std.debug.print("Init SDL\n", .{});

    const sdL_init = c.SDL_Init(c.SDL_INIT_VIDEO);

    if (!sdL_init) {
        std.debug.print("Could not init SDL3: {s}\n", .{c.SDL_GetError()});
        return;
    }

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 0);

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_RED_SIZE, 8);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_GREEN_SIZE, 8);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_BLUE_SIZE, 8);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 0);

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_STENCIL_SIZE, 8);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_ACCELERATED_VISUAL, 1);

    std.debug.print("Init Window\n", .{});

    sdl_window = c.SDL_CreateWindow("UniNote", x, y, c.SDL_WINDOW_OPENGL);

    if (sdl_window == null) {
        std.debug.print("Could not create window: {s}\n", .{c.SDL_GetError()});
        return;
    }

    gl_context = c.SDL_GL_CreateContext(sdl_window);
    _ = c.SDL_GL_SetSwapInterval(1);

    if (gl_context == null) {
        std.debug.print("Could not create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return;
    }

    if (!c.SDL_GL_MakeCurrent(sdl_window, gl_context)) {
        std.debug.print("Set current OpenGL context: {s}\n", .{c.SDL_GetError()});
        return;
    }
}

pub fn deinit() void {
    _ = c.SDL_GL_DestroyContext(gl_context);

    c.SDL_DestroyWindow(sdl_window);
    c.SDL_Quit();
}

pub fn getNativeWindow() ?*c.SDL_Window {
    return sdl_window;
}

pub fn getNativeOpengl() ?*c.SDL_GLContextState {
    return gl_context;
}

pub fn getEvent() ?c.SDL_Event {
    var e: c.SDL_Event = undefined;

    if (c.SDL_PollEvent(&e))
        return e;

    return null;
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

pub fn draw() void {
    _ = c.SDL_GL_SwapWindow(sdl_window);
}
