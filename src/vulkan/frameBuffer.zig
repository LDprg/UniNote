const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const swapChain = @import("swapChain.zig");
const imageView = @import("imageView.zig");
const renderPass = @import("renderPass.zig");

pub var swapChainFramebuffers: []c.VkFramebuffer = undefined;

pub var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    swapChainFramebuffers = try alloc.alloc(c.VkFramebuffer, imageView.swapChainImageViews.len);

    for (imageView.swapChainImageViews, 0..) |imageViews, i| {
        const framebufferInfo = c.VkFramebufferCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = renderPass.renderPass,
            .attachmentCount = 1,
            .pAttachments = &imageViews,
            .width = swapChain.extent.width,
            .height = swapChain.extent.height,
            .layers = 1,
        };

        try util.check_vk(c.vkCreateFramebuffer(device.device, &framebufferInfo, null, &swapChainFramebuffers[i]));
    }
}

pub fn deinit() void {
    for (swapChainFramebuffers) |framebuffer| {
        c.vkDestroyFramebuffer(device.device, framebuffer, null);
    }
}
