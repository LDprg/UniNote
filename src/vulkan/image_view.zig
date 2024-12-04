const std = @import("std");

const c = @import("../c.zig");

const device = @import("device.zig");
const swapchain = @import("swapchain.zig");
const util = @import("util.zig");

pub var swapchain_image_views: []c.VkImageView = undefined;

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    swapchain_image_views = try alloc.alloc(c.VkImageView, swapchain.swapchain_images.len);
    for (swapchain.swapchain_images, 0..) |sawpchain_image, i| {
        const create_info = c.VkImageViewCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = sawpchain_image,
            .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
            .format = swapchain.format.format,
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
        try util.check_vk(c.vkCreateImageView(device.device, &create_info, null, &swapchain_image_views[i]));
    }
}

pub fn deinit() void {
    for (swapchain_image_views) |image_view| {
        c.vkDestroyImageView(device.device, image_view, null);
    }
}
