const std = @import("std");

const c = @import("../c.zig");

const window = @import("../window.zig");

const device = @import("device.zig");
const physical_device = @import("physical_device.zig");
const queue_family = @import("queue_family.zig");
const surface = @import("surface.zig");
const util = @import("util.zig");

pub var swapchain: c.VkSwapchainKHR = undefined;
pub var swapchain_images: []c.VkImage = undefined;

pub var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
pub var formats: []c.VkSurfaceFormatKHR = undefined;
pub var present_modes: []c.VkPresentModeKHR = undefined;

pub var format: c.VkSurfaceFormatKHR = undefined;
pub var present_mode: c.VkPresentModeKHR = undefined;
pub var extent: c.VkExtent2D = undefined;
pub var image_sharing_mode: u32 = undefined;

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    // init capabilities
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device.physical_device, surface.surface, &capabilities));

    // init formats
    var format_count: u32 = 0;
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device.physical_device, surface.surface, &format_count, null));

    formats = try alloc.alloc(c.VkSurfaceFormatKHR, format_count);
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_device.physical_device, surface.surface, &format_count, formats.ptr));
    try std.testing.expect(formats.len > 0);

    for (formats) |value| {
        if (value.format == c.VK_FORMAT_B8G8R8A8_UNORM and value.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            format = value;
            break;
        }
    }

    // init presentMode
    var present_mode_count: u32 = 0;
    try util.check_vk(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
        physical_device.physical_device,
        surface.surface,
        &present_mode_count,
        null,
    ));

    present_modes = try alloc.alloc(c.VkPresentModeKHR, present_mode_count);
    try util.check_vk(c.vkGetPhysicalDeviceSurfacePresentModesKHR(
        physical_device.physical_device,
        surface.surface,
        &present_mode_count,
        present_modes.ptr,
    ));
    try std.testing.expect(present_modes.len > 0);

    present_mode = c.VK_PRESENT_MODE_FIFO_KHR;
    for (present_modes) |value| {
        if (value == c.VK_PRESENT_MODE_MAILBOX_KHR) {
            present_mode = value;
            break;
        }
    }

    // choose extend
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        extent = capabilities.currentExtent;
    } else {
        const size = window.getSize();

        extent = c.VkExtent2D{
            .width = std.math.clamp(size.x, capabilities.minImageExtent.width, capabilities.maxImageExtent.width),
            .height = std.math.clamp(size.y, capabilities.minImageExtent.height, capabilities.maxImageExtent.height),
        };
    }

    // choose imageCount
    var image_count = capabilities.minImageCount + 1;
    if (capabilities.maxImageCount > 0 and image_count > capabilities.maxImageCount) {
        image_count = capabilities.maxImageCount;
    }

    var create_info = c.VkSwapchainCreateInfoKHR{
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = surface.surface,
        .minImageCount = image_count,
        .imageFormat = format.format,
        .imageColorSpace = format.colorSpace,
        .imageExtent = extent,
        .imageArrayLayers = 1,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .preTransform = capabilities.currentTransform,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = present_mode,
        .clipped = c.VK_TRUE,
        .oldSwapchain = null,
    };

    const queue_family_indices: []const u32 = &.{
        queue_family.graphics_family.?,
        queue_family.present_family.?,
    };

    if (queue_family.graphics_family != queue_family.present_family) {
        image_sharing_mode = c.VK_SHARING_MODE_CONCURRENT;
        create_info.queueFamilyIndexCount = @intCast(queue_family_indices.len);
        create_info.pQueueFamilyIndices = queue_family_indices.ptr;
    } else {
        image_sharing_mode = c.VK_SHARING_MODE_EXCLUSIVE;
        create_info.queueFamilyIndexCount = 0;
        create_info.pQueueFamilyIndices = null;
    }
    create_info.imageSharingMode = image_sharing_mode;

    try util.check_vk(c.vkCreateSwapchainKHR(device.device, &create_info, null, &swapchain));

    try util.check_vk(c.vkGetSwapchainImagesKHR(device.device, swapchain, &image_count, null));

    swapchain_images = try alloc.alloc(c.VkImage, image_count);
    try util.check_vk(c.vkGetSwapchainImagesKHR(device.device, swapchain, &image_count, swapchain_images.ptr));
}

pub fn deinit() void {
    c.vkDestroySwapchainKHR(device.device, swapchain, null);
}
