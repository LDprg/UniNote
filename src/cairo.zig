const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

var sdl_texture: *c.SDL_Texture = undefined;
var sdl_surface: *c.SDL_Surface = undefined;

var surface: ?*c.cairo_surface_t = undefined;
var cairo: ?*c.cairo_t = undefined;

pub fn init() !void {
    const size = window.getSize();
    sdl_texture = c.SDL_CreateTexture(window.getNativeRenderer(), c.SDL_PIXELFORMAT_ABGR32, c.SDL_TEXTUREACCESS_STREAMING, size.x, size.y);

    sdl_surface = c.SDL_CreateSurface(size.x, size.y, c.SDL_PIXELFORMAT_ABGR32);

    surface = c.cairo_image_surface_create_for_data(@as([*]u8, @ptrCast(sdl_surface.*.pixels.?)), c.CAIRO_FORMAT_ARGB32, sdl_surface.*.w, sdl_surface.*.h, sdl_surface.*.pitch);

    if (surface == null) {
        std.debug.print("Could not create cairo_surface!\n", .{});
        return;
    }

    cairo = c.cairo_create(surface);

    if (cairo == null) {
        std.debug.print("Could not create cairo_render!\n", .{});
        return;
    }

    c.cairo_set_source_rgb(cairo, 1.0, 1.0, 1.0);
    c.cairo_paint(cairo);

    c.cairo_set_source_rgb(cairo, 0.0, 0.0, 1.0);
    c.cairo_rectangle(cairo, 100, 30, 200, 150);
    c.cairo_fill(cairo);
}

pub fn deinit() void {
    c.cairo_destroy(cairo);
    c.cairo_surface_destroy(surface);
    c.SDL_DestroySurface(sdl_surface);
    c.SDL_DestroyTexture(sdl_texture);
}

pub fn update() void {
    _ = c.SDL_UpdateTexture(sdl_texture, null, @as([*]u8, @ptrCast(sdl_surface.*.pixels.?)), sdl_surface.*.pitch);
}

pub fn draw() void {
    _ = c.SDL_RenderTexture(window.getNativeRenderer(), sdl_texture, null, null);
}
