const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const uniformBuffers = @import("uniformBuffers.zig");
const descriptorPool = @import("descriptorPool.zig");
const descriptorSetLayout = @import("descriptorSetLayout.zig");

pub var descriptorSets: []c.VkDescriptorSet = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    const layouts = try alloc.alloc(c.VkDescriptorSetLayout, util.maxFramesInFligth);
    @memset(layouts, descriptorSetLayout.descriptorSetLayout);

    const allocInfo = c.VkDescriptorSetAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = descriptorPool.descriptorPool,
        .descriptorSetCount = @intCast(util.maxFramesInFligth),
        .pSetLayouts = layouts.ptr,
    };

    descriptorSets = try alloc.alloc(c.VkDescriptorSet, util.maxFramesInFligth);

    try util.check_vk(c.vkAllocateDescriptorSets(device.device, &allocInfo, descriptorSets.ptr));

    for (0..util.maxFramesInFligth) |i| {
        const bufferInfo = c.VkDescriptorBufferInfo{
            .buffer = uniformBuffers.uniformBuffers[i],
            .offset = 0,
            .range = c.VK_WHOLE_SIZE,
        };

        const descriptorWrite = c.VkWriteDescriptorSet{
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = descriptorSets[i],
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
            .pBufferInfo = &bufferInfo,
            .pImageInfo = null,
            .pTexelBufferView = null,
        };

        c.vkUpdateDescriptorSets(device.device, 1, &descriptorWrite, 0, null);
    }
}
