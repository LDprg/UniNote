const std = @import("std");

const c = @import("root").c;

const physical_device = @import("root").renderer.vulkan.physical_device;
const surface = @import("root").renderer.vulkan.surface;
const util = @import("root").renderer.vulkan.util;

pub var graphics_family: ?u32 = undefined;
pub var present_family: ?u32 = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    var count: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(physical_device.physical_device, &count, null);

    const queues = try alloc.alloc(c.VkQueueFamilyProperties, count);
    defer alloc.free(queues);

    c.vkGetPhysicalDeviceQueueFamilyProperties(physical_device.physical_device, &count, queues.ptr);

    for (queues, 0..) |queue, i| {
        if (queue.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            graphics_family = @intCast(i);
        }

        var present_support: c.VkBool32 = c.VK_FALSE;
        try util.check_vk(c.vkGetPhysicalDeviceSurfaceSupportKHR(
            physical_device.physical_device,
            @intCast(i),
            surface.surface,
            &present_support,
        ));
        if (present_support == c.VK_TRUE) {
            present_family = @intCast(i);
        }
    }

    try std.testing.expect(graphics_family != null);
    try std.testing.expect(present_family != null);
}
