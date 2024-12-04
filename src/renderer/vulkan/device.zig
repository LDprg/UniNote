const std = @import("std");

const c = @import("root").c;

const instance = @import("root").renderer.vulkan.instance;
const physical_device = @import("root").renderer.vulkan.physical_device;
const queue_family = @import("root").renderer.vulkan.queue_family;
const util = @import("root").renderer.vulkan.util;

var queue_priority: f32 = 1.0;

pub var device: c.VkDevice = undefined;

pub var extensions: []const ?[*]const u8 = &.{
    c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    c.VK_KHR_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME,
};

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    var queue_create_infos = std.ArrayList(c.VkDeviceQueueCreateInfo).init(alloc);
    defer queue_create_infos.deinit();

    const unique_queue_families = [_]u32{
        queue_family.graphics_family.?,
        queue_family.present_family.?,
    };

    for (unique_queue_families) |family| {
        const queue_create_info = c.VkDeviceQueueCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = family,
            .queueCount = 1,
            .pQueuePriorities = &queue_priority,
        };
        try queue_create_infos.append(queue_create_info);
    }

    const device_features = c.VkPhysicalDeviceFeatures{};

    const create_info = c.VkDeviceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = @intCast(queue_create_infos.items.len),
        .pQueueCreateInfos = queue_create_infos.items.ptr,
        .pEnabledFeatures = &device_features,
        .enabledLayerCount = @intCast(instance.layers.len),
        .ppEnabledLayerNames = instance.layers.ptr,
        .enabledExtensionCount = @intCast(extensions.len),
        .ppEnabledExtensionNames = extensions.ptr,
    };

    try util.check_vk(c.vkCreateDevice(physical_device.physical_device, &create_info, null, &device));
}

pub fn deinit() void {
    c.vkDestroyDevice(device, null);
}
