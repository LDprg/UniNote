const std = @import("std");
const protobuf = @import("protobuf");

const cairo = @cImport(@cInclude("cairo/cairo.h"));
const imgui = @cImport({
    @cInclude("SDL3/SDL.h");
    @cDefine("CIMGUI_USE_SDL3", "TRUE");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "TRUE");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
    @cInclude("cimgui_impl_sdlrenderer3.h");
});
const sdl = imgui;

const window = @import("window.zig");

const test_pb = @import("proto/test.pb.zig");

const x = 640;
const y = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    window.init(x, y);
    defer window.deinit();

    const renderer = sdl.SDL_CreateRenderer(window.getNative(), null);
    defer sdl.SDL_DestroyRenderer(renderer);

    if (renderer == null) {
        std.debug.print("Could not create renderer: {s}\n", .{sdl.SDL_GetError()});
        return;
    }

    // imgui
    _ = imgui.igCreateContext(null);
    defer imgui.igDestroyContext(null);

    var io: *imgui.ImGuiIO = imgui.igGetIO();
    io.ConfigFlags |= imgui.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    io.ConfigFlags |= imgui.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls

    imgui.igStyleColorsDark(null);

    _ = imgui.ImGui_ImplSDL3_InitForSDLRenderer(window.getNative(), renderer);
    defer imgui.ImGui_ImplSDL3_Shutdown();

    _ = imgui.ImGui_ImplSDLRenderer3_Init(renderer);
    defer imgui.ImGui_ImplSDLRenderer3_Shutdown();

    _ = imgui.SDL_SetRenderVSync(renderer, 1);

    // cairo init
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
        var e: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e)) {
            _ = imgui.ImGui_ImplSDL3_ProcessEvent(&e);

            if (e.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        _ = imgui.ImGui_ImplSDLRenderer3_NewFrame();
        _ = imgui.ImGui_ImplSDL3_NewFrame();
        _ = imgui.igNewFrame();

        // Update the SDL texture with the Cairo surface
        _ = sdl.SDL_UpdateTexture(texture, null, @as([*]u8, @ptrCast(surface.*.pixels.?)), surface.*.pitch);

        imgui.igShowDemoWindow(null);

        imgui.igRender();

        // Render the texture to the window
        _ = sdl.SDL_RenderClear(renderer);

        _ = sdl.SDL_RenderTexture(renderer, texture, null, null);
        imgui.ImGui_ImplSDLRenderer3_RenderDrawData(imgui.igGetDrawData(), renderer);

        _ = sdl.SDL_RenderPresent(renderer);
    }
}
