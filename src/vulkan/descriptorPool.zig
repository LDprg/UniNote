const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");

pub var descriptorPool: c.VkDescriptorPool = undefined;

pub fn init() !void {
    const poolSize = c.VkDescriptorPoolSize{
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = @intCast(util.maxFramesInFligth),
    };

    const poolInfo = c.VkDescriptorPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &poolSize,
        .maxSets = @intCast(util.maxFramesInFligth),
    };

    try util.check_vk(c.vkCreateDescriptorPool(device.device, &poolInfo, null, &descriptorPool));
}

pub fn deinit() void {
    c.vkDestroyDescriptorPool(device.device, descriptorPool, null);
}
