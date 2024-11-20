const std = @import("std");
const protobuf = @import("protobuf");

const c = @import("c.zig");

const window = @import("window.zig");
const imgui = @import("imgui.zig");

const test_pb = @import("proto/test.pb.zig");

const x = 640;
const y = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    window.init(x, y);
    defer window.deinit();

    // imgui
    imgui.init();
    defer imgui.deinit();

    // cairo init
    const texture = c.SDL_CreateTexture(window.getNativeRenderer(), c.SDL_PIXELFORMAT_ABGR32, c.SDL_TEXTUREACCESS_STREAMING, x, y);
    defer c.SDL_DestroyTexture(texture);

    const surface = c.SDL_CreateSurface(x, y, c.SDL_PIXELFORMAT_ABGR32);
    defer c.SDL_DestroySurface(surface);

    const cairo_surface = c.cairo_image_surface_create_for_data(@as([*]u8, @ptrCast(surface.*.pixels.?)), c.CAIRO_FORMAT_ARGB32, surface.*.w, surface.*.h, surface.*.pitch);
    defer c.cairo_surface_destroy(cairo_surface);

    if (cairo_surface == null) {
        std.debug.print("Could not create cairo_surface!\n", .{});
        return;
    }

    const cairo_render = c.cairo_create(cairo_surface);
    defer c.cairo_destroy(cairo_render);

    if (cairo_render == null) {
        std.debug.print("Could not create cairo_render!\n", .{});
        return;
    }

    c.cairo_set_source_rgb(cairo_render, 1.0, 1.0, 1.0);
    c.cairo_paint(cairo_render);

    c.cairo_set_source_rgb(cairo_render, 0.0, 0.0, 1.0);
    c.cairo_rectangle(cairo_render, 100, 100, 200, 150);
    c.cairo_fill(cairo_render);

    // protobuf
    const file = try std.fs.cwd().createFile(
        "test.bin",
        .{ .read = true },
    );
    defer file.close();

    var test_person = test_pb.Person.init(alloc);
    defer test_person.deinit();

    test_person.name = protobuf.ManagedString.static("test123");
    test_person.id = 0xFF;

    const data = try test_person.encode(alloc);
    defer alloc.free(data);

    _ = try file.writeAll(data);

    // compression
    const file2 = try std.fs.cwd().createFile(
        "test.bin.lz",
        .{ .read = true },
    );
    defer file2.close();

    var comp = try std.compress.zlib.compressor(file2.writer(), .{});
    _ = try comp.write(data);
    try comp.finish();

    var quit = false;

    while (!quit) {
        var e: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&e)) {
            imgui.processEvent(&e);

            if (e.type == c.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        imgui.nextFrame();

        // Update the SDL texture with the Cairo surface
        _ = c.SDL_UpdateTexture(texture, null, @as([*]u8, @ptrCast(surface.*.pixels.?)), surface.*.pitch);

        c.igShowDemoWindow(null);

        // Render the texture to the window
        _ = c.SDL_RenderClear(window.getNativeRenderer());

        _ = c.SDL_RenderTexture(window.getNativeRenderer(), texture, null, null);
        imgui.render();

        _ = c.SDL_RenderPresent(window.getNativeRenderer());
    }
}
