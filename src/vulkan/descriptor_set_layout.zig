const std = @import("std");

const c = @import("../c.zig");

const device = @import("device.zig");
const util = @import("util.zig");

pub var descriptor_set_layout: c.VkDescriptorSetLayout = undefined;

pub fn init() !void {
    const ubo_layout_binding = c.VkDescriptorSetLayoutBinding{
        .binding = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    };

    const layout_info = c.VkDescriptorSetLayoutCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &ubo_layout_binding,
    };

    try util.check_vk(c.vkCreateDescriptorSetLayout(device.device, &layout_info, null, &descriptor_set_layout));
}

pub fn deinit() void {
    c.vkDestroyDescriptorSetLayout(device.device, descriptor_set_layout, null);
}
