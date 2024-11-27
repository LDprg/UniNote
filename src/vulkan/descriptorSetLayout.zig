const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");

pub var descriptorSetLayout: c.VkDescriptorSetLayout = undefined;

pub fn init() !void {
    const uboLayoutBinding = c.VkDescriptorSetLayoutBinding{
        .binding = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    };

    const layoutInfo = c.VkDescriptorSetLayoutCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &uboLayoutBinding,
    };

    try util.check_vk(c.vkCreateDescriptorSetLayout(device.device, &layoutInfo, null, &descriptorSetLayout));
}

pub fn deinit() void {
    c.vkDestroyDescriptorSetLayout(device.device, descriptorSetLayout, null);
}
