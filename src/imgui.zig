const std = @import("std");

const vulkan = @import("vulkan.zig");

const c = @import("c.zig");

const window = @import("window.zig");

var context: ?*c.ImGuiContext = undefined;

var pipelineCache: c.VkPipelineCache = undefined;
var descriptorPool: c.VkDescriptorPool = undefined;

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

    const pool_sizes: []const c.VkDescriptorPoolSize = &.{
        .{ .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, .descriptorCount = 1000 },
    };

    const pool_info = c.VkDescriptorPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .flags = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
        .maxSets = 1000 * pool_sizes.len,
        .poolSizeCount = pool_sizes.len,
        .pPoolSizes = pool_sizes.ptr,
    };

    try vulkan.util.check_vk(c.vkCreateDescriptorPool(vulkan.device.device, &pool_info, null, &descriptorPool));

    var init_info = c.ImGui_ImplVulkan_InitInfo{
        .Instance = vulkan.instance.instance,
        .PhysicalDevice = vulkan.physicalDevice.physicalDevice,
        .Device = vulkan.device.device,
        .QueueFamily = vulkan.queueFamily.graphicsFamily.?,
        .Queue = vulkan.queue.graphicsQueue,
        .PipelineCache = pipelineCache,
        .DescriptorPool = descriptorPool,
        .RenderPass = vulkan.renderPass.renderPass,
        .Subpass = 0,
        .MinImageCount = vulkan.swapChain.capabilities.minImageCount,
        .ImageCount = @intCast(vulkan.swapChain.swapChainImages.len),
        .MSAASamples = c.VK_SAMPLE_COUNT_1_BIT,
        .Allocator = null,
        .CheckVkResultFn = vulkan.util.check_vk_c,
    };
    _ = c.ImGui_ImplVulkan_Init(&init_info);
    _ = c.ImGui_ImplVulkan_CreateFontsTexture();
}

pub fn deinit() !void {
    std.debug.print("Deinit imgui\n", .{});
    _ = c.vkDeviceWaitIdle(vulkan.device.device);

    _ = c.ImGui_ImplVulkan_DestroyFontsTexture();
    c.ImGui_ImplVulkan_Shutdown();
    c.ImGui_ImplSDL3_Shutdown();

    c.igDestroyContext(context);

    c.vkDestroyDescriptorPool(vulkan.device.device, descriptorPool, null);
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
    if (!vulkan.swapChainRebuild) {
        c.igRender();

        c.ImGui_ImplVulkan_RenderDrawData(c.igGetDrawData(), vulkan.commandBuffer.commandBuffers[vulkan.currentFrame], null);
    } else {
        c.igEndFrame();
    }
}
