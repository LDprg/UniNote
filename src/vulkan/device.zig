const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const instance = @import("instance.zig");
const queueFamily = @import("queueFamily.zig");
const physicalDevice = @import("physicalDevice.zig");

var queuePriority: f32 = 1.0;

pub var device: c.VkDevice = undefined;

pub const extensions: []const [*]const u8 = &.{
    c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
};

pub fn init(alloc: std.mem.Allocator) !void {
    var queueCreateInfos = std.ArrayList(c.VkDeviceQueueCreateInfo).init(alloc);
    defer queueCreateInfos.deinit();

    const uniqueQueueFamilies = [_]u32{
        queueFamily.graphicsFamily.?,
        queueFamily.presentFamily.?,
    };

    for (uniqueQueueFamilies) |family| {
        const queueCreateInfo = c.VkDeviceQueueCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = family,
            .queueCount = 1,
            .pQueuePriorities = &queuePriority,
        };
        try queueCreateInfos.append(queueCreateInfo);
    }

    const deviceFeatures = c.VkPhysicalDeviceFeatures{};

    const createInfo = c.VkDeviceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = @intCast(queueCreateInfos.items.len),
        .pQueueCreateInfos = queueCreateInfos.items.ptr,
        .pEnabledFeatures = &deviceFeatures,
        .enabledLayerCount = instance.layers.len,
        .ppEnabledLayerNames = instance.layers.ptr,
        .enabledExtensionCount = extensions.len,
        .ppEnabledExtensionNames = extensions.ptr,
    };

    try util.check_vk(c.vkCreateDevice(physicalDevice.physicalDevice, &createInfo, null, &device));
}

pub fn deinit() void {
    c.vkDestroyDevice(device, null);
}
