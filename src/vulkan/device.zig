const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const instance = @import("instance.zig");
const queueFamily = @import("queueFamily.zig");
const physicalDevice = @import("physicalDevice.zig");

const queuePriority: f32 = 1.0;

pub var device: c.VkDevice = undefined;

pub fn init() !void {
    const queueCreateInfo = c.VkDeviceQueueCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queueFamily.graphicsFamily.?,
        .queueCount = 1,
        .pQueuePriorities = &queuePriority,
    };

    const deviceFeatures = c.VkPhysicalDeviceFeatures{};

    const createInfo = c.VkDeviceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pQueueCreateInfos = &queueCreateInfo,
        .queueCreateInfoCount = 1,
        .pEnabledFeatures = &deviceFeatures,
        .enabledLayerCount = instance.layers.len,
        .ppEnabledLayerNames = instance.layers.ptr,
    };

    try util.check_vk(c.vkCreateDevice(physicalDevice.physicalDevice, &createInfo, null, &device));
}

pub fn deinit() void {
    c.vkDestroyDevice(device, null);
}
