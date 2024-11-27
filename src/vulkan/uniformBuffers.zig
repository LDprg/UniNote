const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const allocator = @import("allocator.zig");
const vertexBuffer = @import("vertexBuffer.zig");

pub const UniformBufferObject = struct {
    scale: [2]f32,
};

pub var uniformBuffers: []c.VkBuffer = undefined;
pub var uniformBuffersAlloc: []c.VmaAllocation = undefined;
pub var uniformBuffersAllocInfo: []c.VmaAllocationInfo = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    const bufferSize: c.VkDeviceSize = @sizeOf(UniformBufferObject);

    uniformBuffers = try alloc.alloc(c.VkBuffer, util.maxFramesInFligth);
    uniformBuffersAlloc = try alloc.alloc(c.VmaAllocation, util.maxFramesInFligth);
    uniformBuffersAllocInfo = try alloc.alloc(c.VmaAllocationInfo, util.maxFramesInFligth);

    for (0..util.maxFramesInFligth) |i| {
        try vertexBuffer.createBuffer(bufferSize, c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT, &uniformBuffers[i], &uniformBuffersAlloc[i], &uniformBuffersAllocInfo[i]);
    }
}

pub fn deinit() void {
    for (uniformBuffers, uniformBuffersAlloc) |buffer, alloca| {
        c.vmaDestroyBuffer(allocator.allocator, buffer, alloca);
    }
}
