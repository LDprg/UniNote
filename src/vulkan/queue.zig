const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const queueFamily = @import("queueFamily.zig");
const device = @import("device.zig");

pub var graphicsQueue: c.VkQueue = undefined;
pub var presentQueue: c.VkQueue = undefined;

pub fn init() !void {
    c.vkGetDeviceQueue(device.device, queueFamily.graphicsFamily.?, 0, &graphicsQueue);
    c.vkGetDeviceQueue(device.device, queueFamily.presentFamily.?, 0, &presentQueue);
}
