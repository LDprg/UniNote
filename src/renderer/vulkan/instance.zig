const std = @import("std");
const builtin = @import("builtin");

const c = @import("root").c;

const window = @import("root").window;

const util = @import("root").renderer.vulkan.util;

pub var instance: c.VkInstance = undefined;

/// VK_LAYER_KHRONOS_validation can cause memory leaks, be aware of this
pub const layers: []const [*]const u8 = switch (builtin.mode) {
    .Debug => &.{
        "VK_LAYER_KHRONOS_validation",
    },
    else => &.{},
};
pub var extensions: []?[*]const u8 = undefined;

pub fn init() !void {
    const app_info = c.VkApplicationInfo{
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

    std.log.debug("Vulkan instance extensions:", .{});
    for (extensions) |extension| {
        std.log.debug("- {s}", .{extension.?[0..c.strlen(extension)]});
    }

    std.log.debug("Vulkan instance layers:", .{});
    for (layers) |layer| {
        std.log.debug("- {s}", .{layer[0..c.strlen(layer)]});
    }

    const create_info = c.VkInstanceCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledExtensionCount = @as(u32, @intCast(extensions.len)),
        .ppEnabledExtensionNames = extensions.ptr,
        .enabledLayerCount = @as(u32, @intCast(layers.len)),
        .ppEnabledLayerNames = layers.ptr,
    };

    try util.check_vk(c.vkCreateInstance(&create_info, null, &instance));
}

pub fn deinit() void {
    c.vkDestroyInstance(instance, null);
}
