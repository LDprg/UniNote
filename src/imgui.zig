const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

var context: ?*c.ImGuiContext = undefined;

pub fn init() void {
    context = c.igCreateContext(null);

    if (context == null) {
        std.debug.print("Could not create context!\n", .{});
        return;
    }

    var io: *c.ImGuiIO = c.igGetIO();
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls

    c.igStyleColorsDark(null);

    _ = c.ImGui_ImplSDL3_InitForSDLRenderer(window.getNativeWindow(), window.getNativeRenderer());

    _ = c.ImGui_ImplSDLRenderer3_Init(window.getNativeRenderer());
}

pub fn deinit() void {
    c.ImGui_ImplSDLRenderer3_Shutdown();
    c.ImGui_ImplSDL3_Shutdown();
    c.igDestroyContext(context);
}

pub fn processEvent(e: *c.SDL_Event) void {
    _ = c.ImGui_ImplSDL3_ProcessEvent(e);
}

pub fn nextFrame() void {
    _ = c.ImGui_ImplSDLRenderer3_NewFrame();
    _ = c.ImGui_ImplSDL3_NewFrame();
    _ = c.igNewFrame();
}

pub fn render() void {
    c.igRender();

    c.ImGui_ImplSDLRenderer3_RenderDrawData(c.igGetDrawData(), window.getNativeRenderer());
}
