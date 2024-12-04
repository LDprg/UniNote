const std = @import("std");

const zmath = @import("zmath");

const c = @import("root").c;

const allocator = @import("root").renderer.vulkan.allocator;
const util = @import("root").renderer.vulkan.util;
const vertex_buffer = @import("root").renderer.vulkan.vertex_buffer;

pub const UniformBufferObject = struct {
    model: zmath.Mat,
    view: zmath.Mat,
};

pub var uniform_buffers: []vertex_buffer.Buffer = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    const buffer_size: c.VkDeviceSize = @sizeOf(UniformBufferObject);

    uniform_buffers = try alloc.alloc(vertex_buffer.Buffer, util.max_frames_in_fligth);

    for (0..util.max_frames_in_fligth) |i| {
        try vertex_buffer.createBuffer(
            buffer_size,
            c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT,
            &uniform_buffers[i],
        );
    }
}

pub fn deinit() void {
    for (uniform_buffers) |buffer| {
        c.vmaDestroyBuffer(allocator.allocator, buffer.buffer, buffer.buffer_alloc);
    }
}
