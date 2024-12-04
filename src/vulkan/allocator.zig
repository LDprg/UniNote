const std = @import("std");

const c = @import("../c.zig");

const device = @import("device.zig");
const instance = @import("instance.zig");
const physical_device = @import("physical_device.zig");
const util = @import("util.zig");

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
