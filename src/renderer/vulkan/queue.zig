const std = @import("std");

const c = @import("root").c;

const device = @import("root").renderer.vulkan.device;
const queue_family = @import("root").renderer.vulkan.queue_family;
const util = @import("root").renderer.vulkan.util;

pub var graphics_queue: c.VkQueue = undefined;
pub var present_queue: c.VkQueue = undefined;

pub fn init() !void {
    c.vkGetDeviceQueue(device.device, queue_family.graphics_family.?, 0, &graphics_queue);
    c.vkGetDeviceQueue(device.device, queue_family.present_family.?, 0, &present_queue);
}
