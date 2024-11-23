const std = @import("std");

const c = @import("../c.zig");

const window = @import("../window.zig");

const util = @import("util.zig");
const surface = @import("surface.zig");
const physicalDevice = @import("physicalDevice.zig");
const queueFamily = @import("queueFamily.zig");
const device = @import("device.zig");

pub var swapChain: c.VkSwapchainKHR = undefined;

pub var capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
pub var formats: std.ArrayList(c.VkSurfaceFormatKHR) = undefined;
pub var presentModes: std.ArrayList(c.VkPresentModeKHR) = undefined;

pub var format: c.VkSurfaceFormatKHR = undefined;
pub var presentMode: c.VkPresentModeKHR = undefined;
pub var extent: c.VkExtent2D = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    // init capabilities
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice.physicalDevice, surface.surface, &capabilities));

    // init formats
    var formatCount: u32 = 0;
    formats = std.ArrayList(c.VkSurfaceFormatKHR).init(alloc);
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice.physicalDevice, surface.surface, &formatCount, null));

    try std.testing.expect(formatCount > 0);

    try formats.resize(formatCount);
    try util.check_vk(c.vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice.physicalDevice, surface.surface, &formatCount, formats.items.ptr));

    // init presentMode
    var presentModeCount: u32 = 0;
    presentModes = std.ArrayList(c.VkPresentModeKHR).init(alloc);
    try util.check_vk(c.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice.physicalDevice, surface.surface, &presentModeCount, null));

    try std.testing.expect(presentModeCount > 0);

    try presentModes.resize(presentModeCount);
    try util.check_vk(c.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice.physicalDevice, surface.surface, &presentModeCount, presentModes.items.ptr));

    // choose format
    for (formats.items) |value| {
        if (value.format == c.VK_FORMAT_B8G8R8A8_SRGB and value.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            format = value;
            break;
        }
    }

    // choose presentMode
    presentMode = c.VK_PRESENT_MODE_FIFO_KHR;
    for (presentModes.items) |value| {
        if (value == c.VK_PRESENT_MODE_MAILBOX_KHR) {
            presentMode = value;
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
    var imageCount = capabilities.minImageCount + 1;
    if (capabilities.maxImageCount > 0 and imageCount > capabilities.maxImageCount) {
        imageCount = capabilities.maxImageCount;
    }

    var createInfo = c.VkSwapchainCreateInfoKHR{
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = surface.surface,
        .minImageCount = imageCount,
        .imageFormat = format.format,
        .imageColorSpace = format.colorSpace,
        .imageExtent = extent,
        .imageArrayLayers = 1,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .preTransform = capabilities.currentTransform,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = presentMode,
        .clipped = c.VK_TRUE,
        .oldSwapchain = null,
    };

    const queueFamilyIndices: []const u32 = &.{
        queueFamily.graphicsFamily.?,
        queueFamily.presentFamily.?,
    };

    if (queueFamily.graphicsFamily != queueFamily.presentFamily) {
        createInfo.imageSharingMode = c.VK_SHARING_MODE_CONCURRENT;
        createInfo.queueFamilyIndexCount = @intCast(queueFamilyIndices.len);
        createInfo.pQueueFamilyIndices = queueFamilyIndices.ptr;
    } else {
        createInfo.imageSharingMode = c.VK_SHARING_MODE_EXCLUSIVE;
        createInfo.queueFamilyIndexCount = 0;
        createInfo.pQueueFamilyIndices = null;
    }

    try util.check_vk(c.vkCreateSwapchainKHR(device.device, &createInfo, null, &swapChain));
}

pub fn deinit() void {
    c.vkDestroySwapchainKHR(device.device, swapChain, null);

    presentModes.deinit();
    formats.deinit();
}
