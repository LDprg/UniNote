const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const queueFamily = @import("queueFamily.zig");

pub var imageAvailableSemaphores: [util.maxFramesInFligth]c.VkSemaphore = undefined;
pub var renderFinishedSemaphores: [util.maxFramesInFligth]c.VkSemaphore = undefined;
pub var inFlightFences: [util.maxFramesInFligth]c.VkFence = undefined;

pub fn init() !void {
    var semaphoreInfo = c.VkSemaphoreCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    var fenceInfo = c.VkFenceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    for (0..util.maxFramesInFligth) |i| {
        try util.check_vk(c.vkCreateSemaphore(device.device, &semaphoreInfo, null, &imageAvailableSemaphores[i]));
        try util.check_vk(c.vkCreateSemaphore(device.device, &semaphoreInfo, null, &renderFinishedSemaphores[i]));
        try util.check_vk(c.vkCreateFence(device.device, &fenceInfo, null, &inFlightFences[i]));
    }
}

pub fn deinit() void {
    for (0..util.maxFramesInFligth) |i| {
        c.vkDestroySemaphore(device.device, imageAvailableSemaphores[i], null);
        c.vkDestroySemaphore(device.device, renderFinishedSemaphores[i], null);
        c.vkDestroyFence(device.device, inFlightFences[i], null);
    }
}
