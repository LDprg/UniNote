const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

pub const util = @import("vulkan/util.zig");
pub const instance = @import("vulkan/instance.zig");
pub const physicalDevice = @import("vulkan/physicalDevice.zig");
pub const queueFamily = @import("vulkan/queueFamily.zig");
pub const device = @import("vulkan/device.zig");
pub const queue = @import("vulkan/queue.zig");

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    try instance.init();
    try physicalDevice.init(arena);
    try queueFamily.init(arena);
    try device.init();
    try queue.init();
}

pub fn deinit() void {
    device.deinit();
    instance.deinit();
}
