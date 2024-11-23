const std = @import("std");

const vulkan = @import("vulkan.zig");

const c = @import("c.zig");

const window = @import("window.zig");

var context: ?*c.ImGuiContext = undefined;

var g_MainWindowData: c.ImGui_ImplVulkanH_Window = undefined;
const g_MinImageCount = 2;

pub fn init() !void {
    std.debug.print("Init Imgui\n", .{});

    context = c.igCreateContext(null);

    if (context == null) {
        std.debug.print("Could not create context!\n", .{});
        return;
    }

    var io: *c.ImGuiIO = c.igGetIO();
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= c.ImGuiConfigFlags_NavEnableGamepad;

    _ = c.ImFontAtlas_AddFontFromFileTTF(
        io.Fonts,
        "res/FiraSans-Regular.ttf",
        20,
        null,
        c.ImFontAtlas_GetGlyphRangesDefault(io.Fonts),
    );

    var style: *c.ImGuiStyle = c.igGetStyle();
    style.WindowPadding = c.ImVec2{ .x = 10, .y = 10 };
    style.FramePadding = c.ImVec2{ .x = 5, .y = 5 };
    style.ItemInnerSpacing = c.ImVec2{ .x = 7, .y = 6 };
    style.ItemSpacing = c.ImVec2{ .x = 7, .y = 7 };
    style.ScrollbarSize = 17;
    style.WindowBorderSize = 0;

    c.igStyleColorsDark(null);

    _ = c.ImGui_ImplSDL3_InitForVulkan(window.getNativeWindow());

    var init_info = std.mem.zeroInit(c.ImGui_ImplVulkan_InitInfo, .{
        .Instance = vulkan.g_Instance,
        .PhysicalDevice = vulkan.g_PhysicalDevice,
        .Device = vulkan.g_Device,
        .QueueFamily = vulkan.g_QueueFamily.?,
        .Queue = vulkan.g_Queue,
        .PipelineCache = vulkan.g_PipelineCache,
        .DescriptorPool = vulkan.g_DescriptorPool,
        .RenderPass = g_MainWindowData.RenderPass,
        .Subpass = 0,
        .MinImageCount = g_MinImageCount,
        .ImageCount = g_MainWindowData.ImageCount,
        .MSAASamples = c.VK_SAMPLE_COUNT_1_BIT,
        .Allocator = vulkan.g_Allocator,
        .CheckVkResultFn = vulkan.check_vk_c,
    });
    _ = c.ImGui_ImplVulkan_Init(&init_info);
}

pub fn deinit() !void {
    c.ImGui_ImplVulkan_Shutdown();
    c.ImGui_ImplSDL3_Shutdown();

    c.igDestroyContext(context);

    c.ImGui_ImplVulkanH_DestroyWindow(vulkan.g_Instance, vulkan.g_Device, &g_MainWindowData, vulkan.g_Allocator);
}

pub fn processEvent(e: *const c.SDL_Event) void {
    if (e.type == c.SDL_EVENT_PEN_DOWN) {
        const newE: *const c.SDL_Event = &c.SDL_Event{
            .button = c.SDL_MouseButtonEvent{
                .type = c.SDL_EVENT_MOUSE_BUTTON_DOWN,
                .button = c.SDL_BUTTON_LEFT,
                .x = e.ptouch.x,
                .y = e.ptouch.y,
                .which = e.ptouch.which,
                .windowID = e.ptouch.windowID,
                .timestamp = e.ptouch.timestamp,
                .reserved = e.ptouch.reserved,
            },
        };

        _ = c.ImGui_ImplSDL3_ProcessEvent(newE);
    } else if (e.type == c.SDL_EVENT_PEN_UP) {
        const newE: *const c.SDL_Event = &c.SDL_Event{
            .button = c.SDL_MouseButtonEvent{
                .type = c.SDL_EVENT_MOUSE_BUTTON_UP,
                .button = c.SDL_BUTTON_LEFT,
                .x = e.ptouch.x,
                .y = e.ptouch.y,
                .which = e.ptouch.which,
                .windowID = e.ptouch.windowID,
                .timestamp = e.ptouch.timestamp,
                .reserved = e.ptouch.reserved,
            },
        };

        _ = c.ImGui_ImplSDL3_ProcessEvent(newE);
    } else if (e.type == c.SDL_EVENT_PEN_MOTION) {
        const newE: *const c.SDL_Event = &c.SDL_Event{
            .motion = c.SDL_MouseMotionEvent{
                .type = c.SDL_EVENT_MOUSE_MOTION,
                .x = e.pmotion.x,
                .y = e.pmotion.y,
                .which = e.pmotion.which,
                .windowID = e.pmotion.windowID,
                .timestamp = e.pmotion.timestamp,
                .reserved = e.pmotion.reserved,
            },
        };

        _ = c.ImGui_ImplSDL3_ProcessEvent(newE);
    } else {
        _ = c.ImGui_ImplSDL3_ProcessEvent(e);
    }
}

pub fn update() void {
    _ = c.ImGui_ImplVulkan_NewFrame();
    _ = c.ImGui_ImplSDL3_NewFrame();
    _ = c.igNewFrame();
}

pub fn draw() !void {
    c.igRender();
}
