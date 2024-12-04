const std = @import("std");

const c = @import("root").c;

const allocator = @import("allocator.zig");
const util = @import("util.zig");
const vertex_buffer = @import("vertex_buffer.zig");

pub const UniformBufferObject = struct {
    scale: [2]f32,
};

pub var uniform_buffers: []c.VkBuffer = undefined;
pub var uniform_buffers_alloc: []c.VmaAllocation = undefined;
pub var uniform_buffers_alloc_info: []c.VmaAllocationInfo = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    const buffer_size: c.VkDeviceSize = @sizeOf(UniformBufferObject);

    uniform_buffers = try alloc.alloc(c.VkBuffer, util.max_frames_in_fligth);
    uniform_buffers_alloc = try alloc.alloc(c.VmaAllocation, util.max_frames_in_fligth);
    uniform_buffers_alloc_info = try alloc.alloc(c.VmaAllocationInfo, util.max_frames_in_fligth);

    for (0..util.max_frames_in_fligth) |i| {
        try vertex_buffer.createBuffer(
            buffer_size,
            c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT,
            &uniform_buffers[i],
            &uniform_buffers_alloc[i],
            &uniform_buffers_alloc_info[i],
        );
    }
}

pub fn deinit() void {
    for (uniform_buffers, uniform_buffers_alloc) |buffer, alloca| {
        c.vmaDestroyBuffer(allocator.allocator, buffer, alloca);
    }
}
