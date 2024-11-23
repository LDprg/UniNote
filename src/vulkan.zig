const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

pub const util = @import("vulkan/util.zig");
pub const instance = @import("vulkan/instance.zig");
pub const surface = @import("vulkan/surface.zig");
pub const physicalDevice = @import("vulkan/physicalDevice.zig");
pub const queueFamily = @import("vulkan/queueFamily.zig");
pub const device = @import("vulkan/device.zig");
pub const queue = @import("vulkan/queue.zig");
pub const swapChain = @import("vulkan/swapChain.zig");
pub const imageView = @import("vulkan/imageView.zig");

var arena_state: std.heap.ArenaAllocator = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    arena_state = std.heap.ArenaAllocator.init(alloc);
    const arena = arena_state.allocator();

    try instance.init();
    try surface.init();
    try physicalDevice.init(arena);
    try queueFamily.init(arena);
    try device.init(arena);
    try queue.init();
    try swapChain.init(arena);
    try imageView.init(arena);
}

pub fn deinit() void {
    imageView.deinit();
    swapChain.deinit();
    device.deinit();
    surface.deinit();
    instance.deinit();

    arena_state.deinit();
}
