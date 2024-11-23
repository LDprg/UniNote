const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

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

var arena_state: std.heap.ArenaAllocator = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    arena_state = std.heap.ArenaAllocator.init(alloc);
    const arena = arena_state.allocator();

    try instance.init();
    try surface.init();
    try physicalDevice.init(arena);
    try queueFamily.init(arena);
    try device.init(arena);
    try queue.init();
    try swapChain.init(arena);
    try imageView.init(arena);
    try renderPass.init();
    try frameBuffer.init(arena);
    try commandBuffer.init();
    try syncObjects.init();
}

pub fn deinit() void {
    _ = c.vkDeviceWaitIdle(device.device);

    syncObjects.deinit();
    commandBuffer.deinit();
    frameBuffer.deinit();
    renderPass.deinit();
    imageView.deinit();
    swapChain.deinit();
    device.deinit();
    surface.deinit();
    instance.deinit();

    arena_state.deinit();
}

pub fn draw() !void {
    // Render
    try util.check_vk(c.vkWaitForFences(device.device, 1, &syncObjects.inFlightFence, c.VK_TRUE, c.UINT64_MAX));
    try util.check_vk(c.vkResetFences(device.device, 1, &syncObjects.inFlightFence));

    var imageIndex: u32 = undefined;
    try util.check_vk(c.vkAcquireNextImageKHR(device.device, swapChain.swapChain, c.UINT64_MAX, syncObjects.imageAvailableSemaphore, null, &imageIndex));
    try util.check_vk(c.vkResetCommandBuffer(commandBuffer.commandBuffer, 0));

    try commandBuffer.recordCommandBuffer(commandBuffer.commandBuffer, imageIndex);

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

    try util.check_vk(c.vkQueuePresentKHR(queue.presentQueue, &presentInfo));
}
