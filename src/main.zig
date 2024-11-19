const std = @import("std");
const protobuf = @import("protobuf");

const cairo = @cImport(@cInclude("cairo/cairo.h"));
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const test_pb = @import("proto/test.pb.zig");

const x = 640;
const y = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const init = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    defer sdl.SDL_Quit();

    if (!init) {
        std.debug.print("Could not init SDL3: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    const window = sdl.SDL_CreateWindow("UniNote", x, y, sdl.SDL_WINDOW_OPENGL);
    defer sdl.SDL_DestroyWindow(window);

    if (window == null) {
        std.debug.print("Could not create window: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    const renderer = sdl.SDL_CreateRenderer(window, null);
    defer sdl.SDL_DestroyRenderer(renderer);

    if (renderer == null) {
        std.debug.print("Could not create renderer: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    const texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_ABGR32, sdl.SDL_TEXTUREACCESS_STREAMING, x, y);
    defer sdl.SDL_DestroyTexture(texture);

    const surface = sdl.SDL_CreateSurface(x, y, sdl.SDL_PIXELFORMAT_ABGR32);
    defer sdl.SDL_DestroySurface(surface);

    const cairo_surface = cairo.cairo_image_surface_create_for_data(@as([*]u8, @ptrCast(surface.*.pixels.?)), cairo.CAIRO_FORMAT_ARGB32, surface.*.w, surface.*.h, surface.*.pitch);
    defer cairo.cairo_surface_destroy(cairo_surface);

    if (cairo_surface == null) {
        std.debug.print("Could not create cairo_surface!\n", .{});
        return;
    }

    const cairo_render = cairo.cairo_create(cairo_surface);
    defer cairo.cairo_destroy(cairo_render);

    if (cairo_render == null) {
        std.debug.print("Could not create cairo_render!\n", .{});
        return;
    }

    cairo.cairo_set_source_rgb(cairo_render, 1.0, 1.0, 1.0);
    cairo.cairo_paint(cairo_render);

    cairo.cairo_set_source_rgb(cairo_render, 0.0, 0.0, 1.0);
    cairo.cairo_rectangle(cairo_render, 100, 100, 200, 150);
    cairo.cairo_fill(cairo_render);

    const file = try std.fs.cwd().createFile(
        "test.bin",
        .{ .read = true },
    );
    defer file.close();

    var test_person = test_pb.Person.init(alloc);
    defer test_person.deinit();

    test_person.name = try protobuf.ManagedString.copy("test", alloc);
    test_person.id = 0xFF;

    const data = try test_person.encode(alloc);
    defer alloc.free(data);

    _ = try file.writeAll(data);

    var quit = false;

    while (!quit) {
        var e: ?sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e.?)) {
            if (e.?.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        // Update the SDL texture with the Cairo surface
        _ = sdl.SDL_UpdateTexture(texture, null, @as([*]u8, @ptrCast(surface.*.pixels.?)), surface.*.pitch);

        // Render the texture to the window
        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderTexture(renderer, texture, null, null);
        _ = sdl.SDL_RenderPresent(renderer);

        sdl.SDL_Delay(16); // ~60 FPS
    }
}
