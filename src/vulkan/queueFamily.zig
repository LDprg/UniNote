const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const surface = @import("surface.zig");
const physicalDevice = @import("physicalDevice.zig");

pub var graphicsFamily: ?u32 = undefined;
pub var presentFamily: ?u32 = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    var count: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice.physicalDevice, &count, null);

    const queues = try alloc.alloc(c.VkQueueFamilyProperties, count);
    defer alloc.free(queues);

    c.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice.physicalDevice, &count, queues.ptr);

    for (queues, 0..) |queue, i| {
        if (queue.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            graphicsFamily = @intCast(i);
        }

        var presentSupport: c.VkBool32 = c.VK_FALSE;
        try util.check_vk(c.vkGetPhysicalDeviceSurfaceSupportKHR(physicalDevice.physicalDevice, @intCast(i), surface.surface, &presentSupport));
        if (presentSupport == c.VK_TRUE) {
            presentFamily = @intCast(i);
        }
    }

    try std.testing.expect(graphicsFamily != null);
    try std.testing.expect(presentFamily != null);
}
