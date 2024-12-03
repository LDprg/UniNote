const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const instance = @import("instance.zig");

pub var physicalDevice: c.VkPhysicalDevice = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    var deviceCount: u32 = 0;
    try util.check_vk(c.vkEnumeratePhysicalDevices(instance.instance, &deviceCount, null));
    try std.testing.expect(deviceCount > 0);

    const devices = try alloc.alloc(c.VkPhysicalDevice, deviceCount);
    defer alloc.free(devices);

    try util.check_vk(c.vkEnumeratePhysicalDevices(instance.instance, &deviceCount, devices.ptr));

    // Select gpu
    var useDevice: usize = 0;
    for (0..deviceCount) |i| {
        var properties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(devices[i], &properties);
        if (properties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            useDevice = i;
            break;
        }
    }

    physicalDevice = devices[useDevice];
}
