const std = @import("std");

const zmath = @import("zmath");

const c = @import("root").c;

const device = @import("root").renderer.vulkan.device;
const frame_buffer = @import("root").renderer.vulkan.frame_buffer;
const queue_family = @import("root").renderer.vulkan.queue_family;
const render_pass = @import("root").renderer.vulkan.render_pass;
const swapchain = @import("root").renderer.vulkan.swapchain;
const util = @import("root").renderer.vulkan.util;

pub var command_pool: c.VkCommandPool = undefined;
pub var command_buffers: [util.max_frames_in_fligth]c.VkCommandBuffer = undefined;

pub fn init() !void {
    const pool_info = c.VkCommandPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queue_family.graphics_family.?,
    };

    try util.check_vk(c.vkCreateCommandPool(device.device, &pool_info, null, &command_pool));

    const alloc_info = c.VkCommandBufferAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = util.max_frames_in_fligth,
    };

    try util.check_vk(c.vkAllocateCommandBuffers(device.device, &alloc_info, &command_buffers));
}

pub fn deinit() void {
    c.vkDestroyCommandPool(device.device, command_pool, null);
}

pub fn beginCommandBuffer(cb: c.VkCommandBuffer, image_index: u32) !void {
    const begin_info = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = 0,
        .pInheritanceInfo = null,
    };

    try util.check_vk(c.vkBeginCommandBuffer(cb, &begin_info));

    const clear_color = c.VkClearValue{ .color = .{ .float32 = zmath.f32x4(0.0, 0.0, 0.0, 1.0) } };

    const render_pass_info = c.VkRenderPassBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = render_pass.render_pass,
        .framebuffer = frame_buffer.swapchain_frame_buffers[image_index],
        .renderArea = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = swapchain.extent,
        },
        .clearValueCount = 1,
        .pClearValues = &clear_color,
    };

    c.vkCmdBeginRenderPass(cb, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);
}

pub fn endCommandBuffer(cb: c.VkCommandBuffer) !void {
    c.vkCmdEndRenderPass(cb);
    try util.check_vk(c.vkEndCommandBuffer(cb));
}
