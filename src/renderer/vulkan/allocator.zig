const std = @import("std");

const c = @import("root").c;

const device = @import("root").renderer.vulkan.device;
const instance = @import("root").renderer.vulkan.instance;
const physical_device = @import("root").renderer.vulkan.physical_device;
const util = @import("root").renderer.vulkan.util;

pub var allocator: c.VmaAllocator = undefined;

pub fn init() !void {
    const allocator_info = c.VmaAllocatorCreateInfo{
        .physicalDevice = physical_device.physical_device,
        .device = device.device,
        .instance = instance.instance,
        // .vulkanApiVersion = GetVulkanApiVersion(),
    };

    try util.check_vk(c.vmaCreateAllocator(&allocator_info, &allocator));
}

pub fn deinit() void {
    c.vmaDestroyAllocator(allocator);
}
