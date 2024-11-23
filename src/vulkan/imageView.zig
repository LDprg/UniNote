const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const swapChain = @import("swapChain.zig");

pub var swapChainImageViews: []c.VkImageView = undefined;

pub var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    swapChainImageViews = try alloc.alloc(c.VkImageView, swapChain.swapChainImages.len);
    for (swapChain.swapChainImages, 0..) |sawpChainImage, i| {
        const createInfo = c.VkImageViewCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = sawpChainImage,
            .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
            .format = swapChain.format.format,
            .components = .{
                .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
                .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            },
            .subresourceRange = .{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        };
        try util.check_vk(c.vkCreateImageView(device.device, &createInfo, null, &swapChainImageViews[i]));
    }
}

pub fn deinit() void {
    for (swapChainImageViews) |imageView| {
        c.vkDestroyImageView(device.device, imageView, null);
    }
}
