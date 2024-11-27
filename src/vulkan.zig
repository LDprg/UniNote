const std = @import("std");

const c = @import("c.zig");

const imgui = @import("imgui.zig");

pub const util = @import("vulkan/util.zig");
pub const allocator = @import("vulkan/allocator.zig");
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
pub const vertexBuffer = @import("vulkan/vertexBuffer.zig");
pub const descriptorSetLayout = @import("vulkan/descriptorSetLayout.zig");
pub const uniformBuffers = @import("vulkan/uniformBuffers.zig");

pub var imageIndex: u32 = undefined;
pub var currentFrame: u32 = 0;

pub var swapChainRebuild = false;

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
    try allocator.init();
    try queue.init();
    try swapChain.init(arena);
    try imageView.init(arena);
    try renderPass.init();
    try shaders.init(arena);
    try descriptorSetLayout.init();
    try pipeline.init(arena);
    try frameBuffer.init(arena);
    try commandBuffer.init();
    try syncObjects.init();
    try vertexBuffer.init();
    try uniformBuffers.init(arena);
}

pub fn deinit() void {
    _ = c.vkDeviceWaitIdle(device.device);

    uniformBuffers.deinit();
    vertexBuffer.deinit();
    syncObjects.deinit();
    commandBuffer.deinit();
    frameBuffer.deinit();
    pipeline.deinit();
    descriptorSetLayout.deinit();
    shaders.deinit();
    renderPass.deinit();
    imageView.deinit();
    swapChain.deinit();
    allocator.deinit();
    device.deinit();
    surface.deinit();
    instance.deinit();

    arena_state.deinit();
}

pub fn rebuildSwapChain() !void {
    try util.check_vk(c.vkDeviceWaitIdle(device.device));

    frameBuffer.deinit();
    imageView.deinit();
    swapChain.deinit();

    try swapChain.init(arena);
    try imageView.init(arena);
    try frameBuffer.init(arena);

    swapChainRebuild = false;
}

pub fn clear() !void {
    try util.check_vk(c.vkWaitForFences(device.device, 1, &syncObjects.inFlightFences[currentFrame], c.VK_TRUE, c.UINT64_MAX));

    const res = c.vkAcquireNextImageKHR(device.device, swapChain.swapChain, c.UINT64_MAX, syncObjects.imageAvailableSemaphores[currentFrame], null, &imageIndex);

    if (res == c.VK_ERROR_OUT_OF_DATE_KHR) {
        swapChainRebuild = true;
        return;
    } else if (res != c.VK_SUBOPTIMAL_KHR) {
        try util.check_vk(res);
    }

    try util.check_vk(c.vkResetFences(device.device, 1, &syncObjects.inFlightFences[currentFrame]));
    try util.check_vk(c.vkResetCommandBuffer(commandBuffer.commandBuffers[currentFrame], 0));

    try commandBuffer.beginCommandBuffer(commandBuffer.commandBuffers[currentFrame], imageIndex);

    c.vkCmdBindPipeline(commandBuffer.commandBuffers[currentFrame], c.VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline.graphicsPipeline);

    const vertexBuffers: [*]const c.VkBuffer = &.{vertexBuffer.vertexBuffer};
    const offsets: [*]const c.VkDeviceSize = &.{0};
    c.vkCmdBindVertexBuffers(commandBuffer.commandBuffers[currentFrame], 0, 1, vertexBuffers, offsets);
    c.vkCmdBindIndexBuffer(commandBuffer.commandBuffers[currentFrame], vertexBuffer.indexBuffer, 0, c.VK_INDEX_TYPE_UINT16);

    const viewport = c.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(swapChain.extent.width),
        .height = @floatFromInt(swapChain.extent.height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };
    c.vkCmdSetViewport(commandBuffer.commandBuffers[currentFrame], 0, 1, &viewport);

    const scissor = c.VkRect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = swapChain.extent,
    };
    c.vkCmdSetScissor(commandBuffer.commandBuffers[currentFrame], 0, 1, &scissor);

    c.vkCmdDrawIndexed(commandBuffer.commandBuffers[currentFrame], @intCast(vertexBuffer.indices.len), 1, 0, 0, 0);
}

pub fn draw() !void {
    var ubo = uniformBuffers.UniformBufferObject{
        .scale = [2]f32{ 1, 1 },
    };

    uniformBuffers.uniformBuffersAllocInfo[currentFrame].pMappedData = @ptrCast(&ubo);

    try commandBuffer.endCommandBuffer(commandBuffer.commandBuffers[currentFrame]);

    const waitSemaphores: []const c.VkSemaphore = &.{syncObjects.imageAvailableSemaphores[currentFrame]};
    const waitStages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
    const signalSemaphores: []const c.VkSemaphore = &.{syncObjects.renderFinishedSemaphores[currentFrame]};

    var submitInfo = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = @intCast(waitSemaphores.len),
        .pWaitSemaphores = waitSemaphores.ptr,
        .pWaitDstStageMask = waitStages.ptr,
        .commandBufferCount = 1,
        .pCommandBuffers = &commandBuffer.commandBuffers[currentFrame],
        .signalSemaphoreCount = @intCast(signalSemaphores.len),
        .pSignalSemaphores = signalSemaphores.ptr,
    };

    try util.check_vk(c.vkQueueSubmit(queue.graphicsQueue, 1, &submitInfo, syncObjects.inFlightFences[currentFrame]));

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

    const res = c.vkQueuePresentKHR(queue.presentQueue, &presentInfo);
    if (res == c.VK_ERROR_OUT_OF_DATE_KHR or res == c.VK_SUBOPTIMAL_KHR) {
        swapChainRebuild = true;
    } else {
        try util.check_vk(res);
    }

    currentFrame = (currentFrame + 1) % util.maxFramesInFligth;
}
