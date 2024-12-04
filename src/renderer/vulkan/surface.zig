const std = @import("std");

const c = @import("root").c;

const window = @import("root").core.window;

const instance = @import("root").renderer.vulkan.instance;
const util = @import("root").renderer.vulkan.util;

pub var surface: c.VkSurfaceKHR = undefined;

pub fn init() !void {
    const surface_init = c.SDL_Vulkan_CreateSurface(window.window, instance.instance, null, &surface);
    if (!surface_init) {
        std.debug.panic("Failed to create Vulkan surface.\n", .{});
    }
}

pub fn deinit() void {
    c.SDL_Vulkan_DestroySurface(instance.instance, surface, null);
}
