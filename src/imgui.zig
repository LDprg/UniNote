const std = @import("std");

const vulkan = @import("vulkan.zig");

const c = @import("c.zig");

const window = @import("window.zig");

var context: ?*c.ImGuiContext = undefined;

var g_MainWindowData: c.ImGui_ImplVulkanH_Window = undefined;
const g_MinImageCount = 2;

pub fn init() !void {
    std.debug.print("Init imgui vulkan\n", .{});

    g_MainWindowData = std.mem.zeroes(c.ImGui_ImplVulkanH_Window);

    g_MainWindowData.Surface = window.surface;

    // Check for WSI support
    var res: u32 = undefined;
    try vulkan.check_vk(c.vkGetPhysicalDeviceSurfaceSupportKHR(
        vulkan.g_PhysicalDevice,
        vulkan.g_QueueFamily.?,
        g_MainWindowData.Surface,
        &res,
    ));
    if (res != c.VK_TRUE) {
        std.debug.panic("Error no WSI support on physical device 0\n", .{});
    }

    // Select Surface Format
    const requestSurfaceImageFormat: []const c.VkFormat = &.{
        c.VK_FORMAT_B8G8R8A8_UNORM,
        c.VK_FORMAT_R8G8B8A8_UNORM,
    };
    const requestSurfaceColorSpace: c.VkColorSpaceKHR = c.VK_COLORSPACE_SRGB_NONLINEAR_KHR;
    g_MainWindowData.SurfaceFormat = c.ImGui_ImplVulkanH_SelectSurfaceFormat(
        vulkan.g_PhysicalDevice,
        g_MainWindowData.Surface,
        requestSurfaceImageFormat.ptr,
        requestSurfaceImageFormat.len,
        requestSurfaceColorSpace,
    );

    const present_modes: []const c.VkPresentModeKHR = &.{c.VK_PRESENT_MODE_FIFO_KHR};

    g_MainWindowData.PresentMode = c.ImGui_ImplVulkanH_SelectPresentMode(
        vulkan.g_PhysicalDevice,
        g_MainWindowData.Surface,
        present_modes.ptr,
        present_modes.len,
    );

    std.debug.print("Present mode: {}\n", .{g_MainWindowData.PresentMode});

    // Create SwapChain, RenderPass, Framebuffer, etc.
    try std.testing.expect(g_MinImageCount >= 2);

    const size = window.getSize();

    c.ImGui_ImplVulkanH_CreateOrResizeWindow(
        vulkan.g_Instance,
        vulkan.g_PhysicalDevice,
        vulkan.g_Device,
        &g_MainWindowData,
        vulkan.g_QueueFamily.?,
        vulkan.g_Allocator,
        size.x,
        size.y,
        g_MinImageCount,
    );

    std.debug.print("Init Imgui", .{});

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

    // Upload Fonts
    // Use any command queue
    vulkan.g_CommandPool = g_MainWindowData.Frames[g_MainWindowData.FrameIndex].CommandPool;
    vulkan.g_CommandBuffer = g_MainWindowData.Frames[g_MainWindowData.FrameIndex].CommandBuffer;

    try vulkan.check_vk(c.vkResetCommandPool(vulkan.g_Device, vulkan.g_CommandPool, 0));

    var begin_info = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };
    try vulkan.check_vk(c.vkBeginCommandBuffer(vulkan.g_CommandBuffer, &begin_info));

    _ = c.ImGui_ImplVulkan_CreateFontsTexture();

    var end_info = std.mem.zeroInit(c.VkSubmitInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &vulkan.g_CommandBuffer,
    });
    try vulkan.check_vk(c.vkEndCommandBuffer(vulkan.g_CommandBuffer));
    try vulkan.check_vk(c.vkQueueSubmit(vulkan.g_Queue, 1, &end_info, null));

    try vulkan.check_vk(c.vkDeviceWaitIdle(vulkan.g_Device));
    _ = c.ImGui_ImplVulkan_DestroyFontsTexture();
}

pub fn deinit() !void {
    try vulkan.check_vk(c.vkDeviceWaitIdle(vulkan.g_Device));

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
    // Resize swap chain
    if (vulkan.g_SwapChainRebuild) {
        const size = window.getSize();
        if (size.x > 0 and size.y > 0) {
            c.ImGui_ImplVulkan_SetMinImageCount(g_MinImageCount);
            c.ImGui_ImplVulkanH_CreateOrResizeWindow(
                vulkan.g_Instance,
                vulkan.g_PhysicalDevice,
                vulkan.g_Device,
                &g_MainWindowData,
                vulkan.g_QueueFamily.?,
                vulkan.g_Allocator,
                size.x,
                size.y,
                g_MinImageCount,
            );
            g_MainWindowData.FrameIndex = 0;
            vulkan.g_SwapChainRebuild = false;
        }
    }

    _ = c.ImGui_ImplVulkan_NewFrame();
    _ = c.ImGui_ImplSDL3_NewFrame();
    _ = c.igNewFrame();
}

pub fn draw() !void {
    c.igRender();

    const draw_data: *c.ImDrawData = c.igGetDrawData();
    const is_minimized = draw_data.DisplaySize.x <= 0.0 or draw_data.DisplaySize.y <= 0.0;
    if (!is_minimized) {
        g_MainWindowData.ClearValue.color.float32 = [4]f32{ 1.0, 1.0, 1.0, 1.0 };
        g_MainWindowData.ClearValue.depthStencil.stencil = 8;

        try vkRender(draw_data);
        try vkPresent();
    }
}

fn vkRender(draw_data: *c.ImDrawData) !void {
    const image_acquired_semaphore: c.VkSemaphore = g_MainWindowData.FrameSemaphores[g_MainWindowData.SemaphoreIndex].ImageAcquiredSemaphore;
    const render_complete_semaphore: c.VkSemaphore = g_MainWindowData.FrameSemaphores[g_MainWindowData.SemaphoreIndex].RenderCompleteSemaphore;
    const err: c.VkResult = c.vkAcquireNextImageKHR(vulkan.g_Device, g_MainWindowData.Swapchain, c.UINT64_MAX, image_acquired_semaphore, null, &g_MainWindowData.FrameIndex);
    if (err == c.VK_ERROR_OUT_OF_DATE_KHR or err == c.VK_SUBOPTIMAL_KHR) {
        vulkan.g_SwapChainRebuild = true;
        return;
    }
    try vulkan.check_vk(err);

    const fd = &g_MainWindowData.Frames[g_MainWindowData.FrameIndex];
    try vulkan.check_vk(c.vkWaitForFences(vulkan.g_Device, 1, &fd.Fence, c.VK_TRUE, c.UINT64_MAX)); // wait indefinitely instead of periodically checking

    try vulkan.check_vk(c.vkResetFences(vulkan.g_Device, 1, &fd.Fence));

    try vulkan.check_vk(c.vkResetCommandPool(vulkan.g_Device, fd.CommandPool, 0));
    const info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });
    try vulkan.check_vk(c.vkBeginCommandBuffer(fd.CommandBuffer, &info));
    const rp_info = std.mem.zeroInit(c.VkRenderPassBeginInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = g_MainWindowData.RenderPass,
        .framebuffer = fd.Framebuffer,
        .renderArea = .{ .extent = .{
            .height = @as(u32, @intCast(g_MainWindowData.Height)),
            .width = @as(u32, @intCast(g_MainWindowData.Width)),
        } },
        .clearValueCount = 1,
        .pClearValues = &g_MainWindowData.ClearValue,
    });
    c.vkCmdBeginRenderPass(fd.CommandBuffer, &rp_info, c.VK_SUBPASS_CONTENTS_INLINE);

    // Record dear imgui primitives into command buffer
    c.ImGui_ImplVulkan_RenderDrawData(draw_data, fd.CommandBuffer, null);

    // Submit command buffer
    c.vkCmdEndRenderPass(fd.CommandBuffer);
    const wait_stage: c.VkPipelineStageFlags = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    var sub_info = std.mem.zeroInit(c.VkSubmitInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &image_acquired_semaphore,
        .pWaitDstStageMask = &wait_stage,
        .commandBufferCount = 1,
        .pCommandBuffers = &fd.CommandBuffer,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &render_complete_semaphore,
    });

    try vulkan.check_vk(c.vkEndCommandBuffer(fd.CommandBuffer));
    try vulkan.check_vk(c.vkQueueSubmit(vulkan.g_Queue, 1, &sub_info, fd.Fence));
}

fn vkPresent() !void {
    if (vulkan.g_SwapChainRebuild) return;

    const render_complete_semaphore: c.VkSemaphore = g_MainWindowData.FrameSemaphores[g_MainWindowData.SemaphoreIndex].RenderCompleteSemaphore;
    const info = std.mem.zeroInit(c.VkPresentInfoKHR, .{
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &render_complete_semaphore,
        .swapchainCount = 1,
        .pSwapchains = &g_MainWindowData.Swapchain,
        .pImageIndices = &g_MainWindowData.FrameIndex,
    });

    const err: c.VkResult = c.vkQueuePresentKHR(vulkan.g_Queue, &info);
    if (err == c.VK_ERROR_OUT_OF_DATE_KHR or err == c.VK_SUBOPTIMAL_KHR) {
        vulkan.g_SwapChainRebuild = true;
        return;
    }
    try vulkan.check_vk(err);

    g_MainWindowData.SemaphoreIndex = (g_MainWindowData.SemaphoreIndex + 1) % g_MainWindowData.ImageCount; // Now we can use the next set of semaphores
}
