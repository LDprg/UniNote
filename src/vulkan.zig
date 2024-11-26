const std = @import("std");

const c = @import("c.zig");

pub const util = @import("vulkan/util.zig");
pub const instance = @import("vulkan/instance.zig");
pub const surface = @import("vulkan/surface.zig");
pub const physicalDevice = @import("vulkan/physicalDevice.zig");
pub const queueFamily = @import("vulkan/queueFamily.zig");
pub const device = @import("vulkan/device.zig");
pub const queue = @import("vulkan/queue.zig");
pub const swapChain = @import("vulkan/swapChain.zig");
pub const imageView = @import("vulkan/imageView.zig");
pub const renderPass = @import("vulkan/renderPass.zig");
pub const frameBuffer = @import("vulkan/frameBuffer.zig");
pub const commandBuffer = @import("vulkan/commandBuffer.zig");
pub const syncObjects = @import("vulkan/syncObjects.zig");
pub const shaders = @import("vulkan/shaders.zig");
pub const pipeline = @import("vulkan/pipeline.zig");

pub var imageIndex: u32 = undefined;

var arena_state: std.heap.ArenaAllocator = undefined;
var arena: std.mem.Allocator = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    arena_state = std.heap.ArenaAllocator.init(alloc);
    arena = arena_state.allocator();

    try instance.init();
    try surface.init();
    try physicalDevice.init(arena);
    try queueFamily.init(arena);
    try device.init(arena);
    try queue.init();
    try swapChain.init(arena);
    try imageView.init(arena);
    try renderPass.init();
    try shaders.init(arena);
    try pipeline.init();
    try frameBuffer.init(arena);
    try commandBuffer.init();
    try syncObjects.init();
}

pub fn deinit() void {
    _ = c.vkDeviceWaitIdle(device.device);

    syncObjects.deinit();
    commandBuffer.deinit();
    frameBuffer.deinit();
    pipeline.deinit();
    shaders.deinit();
    renderPass.deinit();
    imageView.deinit();
    swapChain.deinit();
    device.deinit();
    surface.deinit();
    instance.deinit();

    arena_state.deinit();
}

pub fn recreateSwapChain() !void {
    try util.check_vk(c.vkDeviceWaitIdle(device.device));

    frameBuffer.deinit();
    imageView.deinit();
    swapChain.deinit();

    try swapChain.init(arena);
    try imageView.init(arena);
    try frameBuffer.init(arena);
}

pub fn clear() !void {
    try util.check_vk(c.vkWaitForFences(device.device, 1, &syncObjects.inFlightFence, c.VK_TRUE, c.UINT64_MAX));

    {
        const res = c.vkAcquireNextImageKHR(device.device, swapChain.swapChain, c.UINT64_MAX, syncObjects.imageAvailableSemaphore, null, &imageIndex);

        if (res == c.VK_ERROR_OUT_OF_DATE_KHR) {
            try recreateSwapChain();
            return;
        } else if (res != c.VK_SUBOPTIMAL_KHR) {
            try util.check_vk(res);
        }
    }

    try util.check_vk(c.vkResetFences(device.device, 1, &syncObjects.inFlightFence));
    try util.check_vk(c.vkResetCommandBuffer(commandBuffer.commandBuffer, 0));

    try commandBuffer.beginCommandBuffer(commandBuffer.commandBuffer, imageIndex);

    c.vkCmdBindPipeline(commandBuffer.commandBuffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline.graphicsPipeline);

    const viewport = c.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(swapChain.extent.width),
        .height = @floatFromInt(swapChain.extent.height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };
    c.vkCmdSetViewport(commandBuffer.commandBuffer, 0, 1, &viewport);

    const scissor = c.VkRect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = swapChain.extent,
    };
    c.vkCmdSetScissor(commandBuffer.commandBuffer, 0, 1, &scissor);

    c.vkCmdDraw(commandBuffer.commandBuffer, 3, 1, 0, 0);
}

pub fn draw() !void {
    try commandBuffer.endCommandBuffer(commandBuffer.commandBuffer);

    const waitSemaphores: []const c.VkSemaphore = &.{syncObjects.imageAvailableSemaphore};
    const waitStages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
    const signalSemaphores: []const c.VkSemaphore = &.{syncObjects.renderFinishedSemaphore};

    var submitInfo = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = @intCast(waitSemaphores.len),
        .pWaitSemaphores = waitSemaphores.ptr,
        .pWaitDstStageMask = waitStages.ptr,
        .commandBufferCount = 1,
        .pCommandBuffers = &commandBuffer.commandBuffer,
        .signalSemaphoreCount = @intCast(signalSemaphores.len),
        .pSignalSemaphores = signalSemaphores.ptr,
    };

    try util.check_vk(c.vkQueueSubmit(queue.graphicsQueue, 1, &submitInfo, syncObjects.inFlightFence));

    // Present
    const swapChains: []const c.VkSwapchainKHR = &.{swapChain.swapChain};

    const presentInfo = c.VkPresentInfoKHR{
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = @intCast(signalSemaphores.len),
        .pWaitSemaphores = signalSemaphores.ptr,
        .swapchainCount = @intCast(swapChains.len),
        .pSwapchains = swapChains.ptr,
        .pImageIndices = &imageIndex,
        .pResults = null,
    };

    {
        const res = c.vkQueuePresentKHR(queue.presentQueue, &presentInfo);
        if (res == c.VK_ERROR_OUT_OF_DATE_KHR or res == c.VK_SUBOPTIMAL_KHR) {
            try recreateSwapChain();
        } else {
            try util.check_vk(res);
        }
    }
}
