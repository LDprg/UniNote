const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const instance = @import("instance.zig");
const queueFamily = @import("queueFamily.zig");
const physicalDevice = @import("physicalDevice.zig");

var queuePriority: f32 = 1.0;

pub var device: c.VkDevice = undefined;

pub var extensions: []?[*]const u8 = undefined;

pub var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    var queueCreateInfos = std.ArrayList(c.VkDeviceQueueCreateInfo).init(alloc);
    defer queueCreateInfos.deinit();

    extensions = try alloc.alloc(?[*]const u8, 2);
    extensions[0] = c.VK_KHR_SWAPCHAIN_EXTENSION_NAME;
    extensions[1] = c.VK_KHR_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME;

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
        .enabledLayerCount = @intCast(instance.layers.len),
        .ppEnabledLayerNames = instance.layers.ptr,
        .enabledExtensionCount = @intCast(extensions.len),
        .ppEnabledExtensionNames = extensions.ptr,
    };

    try util.check_vk(c.vkCreateDevice(physicalDevice.physicalDevice, &createInfo, null, &device));
}

pub fn deinit() void {
    c.vkDestroyDevice(device, null);
}
