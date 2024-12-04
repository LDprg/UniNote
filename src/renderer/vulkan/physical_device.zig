const std = @import("std");

const c = @import("root").c;

const instance = @import("instance.zig");
const util = @import("util.zig");

pub var physical_device: c.VkPhysicalDevice = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    var device_count: u32 = 0;
    try util.check_vk(c.vkEnumeratePhysicalDevices(instance.instance, &device_count, null));
    try std.testing.expect(device_count > 0);

    const devices = try alloc.alloc(c.VkPhysicalDevice, device_count);
    defer alloc.free(devices);

    try util.check_vk(c.vkEnumeratePhysicalDevices(instance.instance, &device_count, devices.ptr));

    // Select gpu
    var use_device: usize = 0;
    for (0..device_count) |i| {
        var properties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(devices[i], &properties);
        if (properties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            use_device = i;
            break;
        }
    }

    physical_device = devices[use_device];
}
