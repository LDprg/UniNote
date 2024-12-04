const std = @import("std");

const c = @import("root").c;

const device = @import("root").renderer.vulkan.device;
const image_view = @import("root").renderer.vulkan.image_view;
const render_pass = @import("root").renderer.vulkan.render_pass;
const swapchain = @import("root").renderer.vulkan.swapchain;
const util = @import("root").renderer.vulkan.util;

pub var swapchain_frame_buffers: []c.VkFramebuffer = undefined;

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    swapchain_frame_buffers = try alloc.alloc(c.VkFramebuffer, image_view.swapchain_image_views.len);

    for (image_view.swapchain_image_views, 0..) |image_views, i| {
        const frame_buffer_info = c.VkFramebufferCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = render_pass.render_pass,
            .attachmentCount = 1,
            .pAttachments = &image_views,
            .width = swapchain.extent.width,
            .height = swapchain.extent.height,
            .layers = 1,
        };

        try util.check_vk(c.vkCreateFramebuffer(device.device, &frame_buffer_info, null, &swapchain_frame_buffers[i]));
    }
}

pub fn deinit() void {
    for (swapchain_frame_buffers) |framebuffer| {
        c.vkDestroyFramebuffer(device.device, framebuffer, null);
    }
}
