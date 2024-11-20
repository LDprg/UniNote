const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

var context: ?*c.ImGuiContext = undefined;

pub fn init() !void {
    context = c.igCreateContext(null);

    if (context == null) {
        std.debug.print("Could not create context!\n", .{});
        return;
    }

    var io: *c.ImGuiIO = c.igGetIO();
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard; // Enable Keyboard Controls
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableGamepad; // Enable Gamepad Controls

    _ = c.ImFontAtlas_AddFontFromFileTTF(io.Fonts, "res/FiraSans-Regular.ttf", 20, null, c.ImFontAtlas_GetGlyphRangesDefault(io.Fonts));

    c.igStyleColorsDark(null);

    _ = c.ImGui_ImplSDL3_InitForSDLRenderer(window.getNativeWindow(), window.getNativeRenderer());

    _ = c.ImGui_ImplSDLRenderer3_Init(window.getNativeRenderer());
}

pub fn deinit() void {
    c.ImGui_ImplSDLRenderer3_Shutdown();
    c.ImGui_ImplSDL3_Shutdown();
    c.igDestroyContext(context);
}

pub fn processEvent(e: *const c.SDL_Event) void {
    _ = c.ImGui_ImplSDL3_ProcessEvent(e);
}

pub fn update() void {
    _ = c.ImGui_ImplSDLRenderer3_NewFrame();
    _ = c.ImGui_ImplSDL3_NewFrame();
    _ = c.igNewFrame();
}

pub fn draw() void {
    c.igRender();

    c.ImGui_ImplSDLRenderer3_RenderDrawData(c.igGetDrawData(), window.getNativeRenderer());
}

pub fn showDemoWindow(open: ?*bool) void {
    c.igShowDemoWindow(open);
}

pub fn beginMainMenuBar() bool {
    return c.igBeginMainMenuBar();
}

pub fn endMainMenuBar() void {
    c.igEndMainMenuBar();
}

pub fn beginMenu(label: []const u8, enabled: bool) bool {
    return c.igBeginMenu(@ptrCast(label), enabled);
}

pub fn endMenu() void {
    c.igEndMenu();
}

pub fn MenuItem(label: []const u8, shortcut: []const u8, selected: bool, enabled: bool) bool {
    return c.igMenuItem_Bool(@ptrCast(label), @ptrCast(shortcut), selected, enabled);
}
