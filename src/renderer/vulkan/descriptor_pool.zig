const std = @import("std");

const c = @import("root").c;

const device = @import("device.zig");
const util = @import("util.zig");

pub var descriptor_pool: c.VkDescriptorPool = undefined;

pub fn init() !void {
    const pool_size = c.VkDescriptorPoolSize{
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = @intCast(util.max_frames_in_fligth),
    };

    const pool_info = c.VkDescriptorPoolCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &pool_size,
        .maxSets = @intCast(util.max_frames_in_fligth),
    };

    try util.check_vk(c.vkCreateDescriptorPool(device.device, &pool_info, null, &descriptor_pool));
}

pub fn deinit() void {
    c.vkDestroyDescriptorPool(device.device, descriptor_pool, null);
}
