const std = @import("std");

const c = @import("../c.zig");

const window = @import("../window.zig");

const util = @import("util.zig");

pub var instance: c.VkInstance = undefined;
pub const layers: []const [*]const u8 = &.{"VK_LAYER_KHRONOS_validation"};
pub var extensions: []?[*]const u8 = undefined;

pub fn init() !void {
    const appInfo = c.VkApplicationInfo{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "UniNote",
        .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
        .pEngineName = "No Engine",
        .engineVersion = c.VK_MAKE_VERSION(1, 0, 0),
        .apiVersion = c.VK_API_VERSION_1_0,
    };

    var extensions_count: u32 = 0;
    _ = c.SDL_Vulkan_GetInstanceExtensions(&extensions_count);
    extensions = @constCast(c.SDL_Vulkan_GetInstanceExtensions(&extensions_count)[0..extensions_count]);

    const createInfo = c.VkInstanceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &appInfo,
        .enabledExtensionCount = @as(u32, @intCast(extensions.len)),
        .ppEnabledExtensionNames = extensions.ptr,
        .enabledLayerCount = @as(u32, @intCast(layers.len)),
        .ppEnabledLayerNames = layers.ptr,
    };

    try util.check_vk(c.vkCreateInstance(&createInfo, null, &instance));
}

pub fn deinit() void {
    c.vkDestroyInstance(instance, null);
}
