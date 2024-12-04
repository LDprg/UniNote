const std = @import("std");

const c = @import("../c.zig");

const device = @import("device.zig");
const queue_family = @import("queue_family.zig");
const util = @import("util.zig");

pub var image_available_semaphores: [util.max_frames_in_fligth]c.VkSemaphore = undefined;
pub var render_finished_semaphores: [util.max_frames_in_fligth]c.VkSemaphore = undefined;
pub var in_flight_fences: [util.max_frames_in_fligth]c.VkFence = undefined;

pub fn init() !void {
    var semaphore_info = c.VkSemaphoreCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    var fence_info = c.VkFenceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    for (0..util.max_frames_in_fligth) |i| {
        try util.check_vk(c.vkCreateSemaphore(device.device, &semaphore_info, null, &image_available_semaphores[i]));
        try util.check_vk(c.vkCreateSemaphore(device.device, &semaphore_info, null, &render_finished_semaphores[i]));
        try util.check_vk(c.vkCreateFence(device.device, &fence_info, null, &in_flight_fences[i]));
    }
}

pub fn deinit() void {
    for (0..util.max_frames_in_fligth) |i| {
        c.vkDestroySemaphore(device.device, image_available_semaphores[i], null);
        c.vkDestroySemaphore(device.device, render_finished_semaphores[i], null);
        c.vkDestroyFence(device.device, in_flight_fences[i], null);
    }
}
