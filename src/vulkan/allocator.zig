const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const physicalDevice = @import("physicalDevice.zig");
const device = @import("device.zig");
const instance = @import("instance.zig");

pub var allocator: c.VmaAllocator = undefined;

pub fn init() !void {
    const allocatorInfo = c.VmaAllocatorCreateInfo{
        .physicalDevice = physicalDevice.physicalDevice,
        .device = device.device,
        .instance = instance.instance,
        // .vulkanApiVersion = GetVulkanApiVersion(),
    };

    try util.check_vk(c.vmaCreateAllocator(&allocatorInfo, &allocator));
}

pub fn deinit() void {
    c.vmaDestroyAllocator(allocator);
}
