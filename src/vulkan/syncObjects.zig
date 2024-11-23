const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const queueFamily = @import("queueFamily.zig");

pub var imageAvailableSemaphore: c.VkSemaphore = undefined;
pub var renderFinishedSemaphore: c.VkSemaphore = undefined;
pub var inFlightFence: c.VkFence = undefined;

pub fn init() !void {
    var semaphoreInfo = c.VkSemaphoreCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    };

    var fenceInfo = c.VkFenceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
    };

    try util.check_vk(c.vkCreateSemaphore(device.device, &semaphoreInfo, null, &imageAvailableSemaphore));
    try util.check_vk(c.vkCreateSemaphore(device.device, &semaphoreInfo, null, &renderFinishedSemaphore));
    try util.check_vk(c.vkCreateFence(device.device, &fenceInfo, null, &inFlightFence));
}

pub fn deinit() void {
    c.vkDestroySemaphore(device.device, imageAvailableSemaphore, null);
    c.vkDestroySemaphore(device.device, renderFinishedSemaphore, null);
    c.vkDestroyFence(device.device, inFlightFence, null);
}