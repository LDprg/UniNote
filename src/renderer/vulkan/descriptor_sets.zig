const std = @import("std");

const c = @import("root").c;

const descriptor_pool = @import("root").renderer.vulkan.descriptor_pool;
const descriptor_set_layout = @import("root").renderer.vulkan.descriptor_set_layout;
const device = @import("root").renderer.vulkan.device;
const uniform_buffers = @import("root").renderer.vulkan.uniform_buffers;
const util = @import("root").renderer.vulkan.util;

pub var descriptor_sets: []c.VkDescriptorSet = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    const layouts = try alloc.alloc(c.VkDescriptorSetLayout, util.max_frames_in_fligth);
    @memset(layouts, descriptor_set_layout.descriptor_set_layout);

    const alloc_info = c.VkDescriptorSetAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = descriptor_pool.descriptor_pool,
        .descriptorSetCount = @intCast(util.max_frames_in_fligth),
        .pSetLayouts = layouts.ptr,
    };

    descriptor_sets = try alloc.alloc(c.VkDescriptorSet, util.max_frames_in_fligth);

    try util.check_vk(c.vkAllocateDescriptorSets(device.device, &alloc_info, descriptor_sets.ptr));

    for (0..util.max_frames_in_fligth) |i| {
        const buffer_info = c.VkDescriptorBufferInfo{
            .buffer = uniform_buffers.uniform_buffers[i],
            .offset = 0,
            .range = c.VK_WHOLE_SIZE,
        };

        const descriptor_write = c.VkWriteDescriptorSet{
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = descriptor_sets[i],
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
            .pBufferInfo = &buffer_info,
            .pImageInfo = null,
            .pTexelBufferView = null,
        };

        c.vkUpdateDescriptorSets(device.device, 1, &descriptor_write, 0, null);
    }
}
