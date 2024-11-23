const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const queueFamily = @import("queueFamily.zig");
const renderPass = @import("renderPass.zig");
const frameBuffer = @import("frameBuffer.zig");
const swapChain = @import("swapChain.zig");

pub var commandPool: c.VkCommandPool = undefined;
pub var commandBuffer: c.VkCommandBuffer = undefined;

pub fn init() !void {
    const poolInfo = c.VkCommandPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queueFamily.graphicsFamily.?,
    };

    try util.check_vk(c.vkCreateCommandPool(device.device, &poolInfo, null, &commandPool));

    const allocInfo = c.VkCommandBufferAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = commandPool,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };

    try util.check_vk(c.vkAllocateCommandBuffers(device.device, &allocInfo, &commandBuffer));
}

pub fn deinit() void {
    c.vkDestroyCommandPool(device.device, commandPool, null);
}

pub fn beginCommandBuffer(cb: c.VkCommandBuffer, imageIndex: u32) !void {
    const beginInfo = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = 0,
        .pInheritanceInfo = null,
    };

    try util.check_vk(c.vkBeginCommandBuffer(cb, &beginInfo));

    const clearColor = c.VkClearValue{ .color = .{ .float32 = [4]f32{ 0.0, 0.0, 0.0, 1.0 } } };

    const renderPassInfo = c.VkRenderPassBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = renderPass.renderPass,
        .framebuffer = frameBuffer.swapChainFramebuffers[imageIndex],
        .renderArea = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = swapChain.extent,
        },
        .clearValueCount = 1,
        .pClearValues = &clearColor,
    };

    c.vkCmdBeginRenderPass(cb, &renderPassInfo, c.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn endCommandBuffer(cb: c.VkCommandBuffer) !void {
    c.vkCmdEndRenderPass(cb);
    try util.check_vk(c.vkEndCommandBuffer(cb));
}
