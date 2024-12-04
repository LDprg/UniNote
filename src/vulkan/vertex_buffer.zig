const std = @import("std");

const c = @import("../c.zig");

const allocator = @import("allocator.zig");
const command_buffer = @import("command_buffer.zig");
const device = @import("device.zig");
const frame_buffer = @import("frame_buffer.zig");
const physical_device = @import("physical_device.zig");
const queue = @import("queue.zig");
const queue_family = @import("queue_family.zig");
const render_pass = @import("render_pass.zig");
const swapchain = @import("swapchain.zig");
const util = @import("util.zig");

pub var vertex_buffer: c.VkBuffer = undefined;
pub var vertex_buffer_alloc: c.VmaAllocation = undefined;

pub var index_buffer: c.VkBuffer = undefined;
pub var index_buffer_alloc: c.VmaAllocation = undefined;

pub const Vertex = struct {
    pos: [2]f32,
    color: [4]f32,

    pub fn getBindingDescription() c.VkVertexInputBindingDescription {
        return c.VkVertexInputBindingDescription{
            .binding = 0,
            .stride = @sizeOf(Vertex),
            .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
        };
    }
    pub fn getAttributeDescriptions(alloc: std.mem.Allocator) ![]c.VkVertexInputAttributeDescription {
        const attribute_descriptions = try alloc.alloc(c.VkVertexInputAttributeDescription, 2);
        attribute_descriptions[0] = .{
            .binding = 0,
            .location = 0,
            .format = c.VK_FORMAT_R32G32_SFLOAT,
            .offset = @offsetOf(Vertex, "pos"),
        };
        attribute_descriptions[1] = .{
            .binding = 0,
            .location = 1,
            .format = c.VK_FORMAT_R32G32B32A32_SFLOAT,
            .offset = @offsetOf(Vertex, "color"),
        };

        return attribute_descriptions;
    }
};

pub var vertices: []Vertex = undefined;
pub var indices: []u16 = undefined;

pub fn createBuffer(size: c.VkDeviceSize, usage: c.VkBufferUsageFlags, flags: c.VmaAllocationCreateFlags, buffer: *c.VkBuffer, bufferAlloc: *c.VmaAllocation, bufferAllocInfo: ?*c.VmaAllocationInfo) !void {
    const buffer_info = c.VkBufferCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = size,
        .usage = usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    const alloc_create_info = c.VmaAllocationCreateInfo{
        .usage = c.VMA_MEMORY_USAGE_AUTO,
        .flags = flags,
    };

    try util.check_vk(c.vmaCreateBuffer(allocator.allocator, &buffer_info, &alloc_create_info, buffer, bufferAlloc, bufferAllocInfo));
}

fn copyBuffer(srcBuffer: c.VkBuffer, dstBuffer: c.VkBuffer, size: c.VkDeviceSize) !void {
    const alloc_info = c.VkCommandBufferAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandPool = command_buffer.command_pool,
        .commandBufferCount = 1,
    };

    var cmdbuff: c.VkCommandBuffer = undefined;
    try util.check_vk(c.vkAllocateCommandBuffers(device.device, &alloc_info, &cmdbuff));

    var begin_info = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };

    try util.check_vk(c.vkBeginCommandBuffer(cmdbuff, &begin_info));

    const copy_region = c.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = size,
    };
    c.vkCmdCopyBuffer(cmdbuff, srcBuffer, dstBuffer, 1, &copy_region);

    try util.check_vk(c.vkEndCommandBuffer(cmdbuff));

    const submit_info = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &cmdbuff,
    };

    try util.check_vk(c.vkQueueSubmit(queue.graphics_queue, 1, &submit_info, null));
    try util.check_vk(c.vkQueueWaitIdle(queue.graphics_queue));

    c.vkFreeCommandBuffers(device.device, command_buffer.command_pool, 1, &cmdbuff);
}

fn createVertexBuffer() !void {
    const buffer_size: c.VkDeviceSize = @sizeOf(Vertex) * vertices.len;

    var staging_buffer: c.VkBuffer = null;
    var staging_buffer_alloc: c.VmaAllocation = null;
    var staging_buffer_alloc_info = c.VmaAllocationInfo{};

    try createBuffer(buffer_size, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT, &staging_buffer, &staging_buffer_alloc, &staging_buffer_alloc_info);

    @memcpy(@as([*]Vertex, @ptrCast(@alignCast(staging_buffer_alloc_info.pMappedData))), vertices);

    try createBuffer(buffer_size, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, 0, &vertex_buffer, &vertex_buffer_alloc, null);

    try copyBuffer(staging_buffer, vertex_buffer, buffer_size);

    c.vmaDestroyBuffer(allocator.allocator, staging_buffer, staging_buffer_alloc);
}

fn createIndexBuffer() !void {
    const buffer_size: c.VkDeviceSize = @sizeOf(Vertex) * vertices.len;

    var staging_buffer: c.VkBuffer = null;
    var staging_buffer_alloc: c.VmaAllocation = null;
    var staging_buffer_alloc_info = c.VmaAllocationInfo{};

    try createBuffer(buffer_size, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT, &staging_buffer, &staging_buffer_alloc, &staging_buffer_alloc_info);

    @memcpy(@as([*]u16, @ptrCast(@alignCast(staging_buffer_alloc_info.pMappedData))), indices);

    try createBuffer(buffer_size, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, 0, &index_buffer, &index_buffer_alloc, null);

    try copyBuffer(staging_buffer, index_buffer, buffer_size);

    c.vmaDestroyBuffer(allocator.allocator, staging_buffer, staging_buffer_alloc);
}

pub fn init() !void {
    var vert = [_]Vertex{
        Vertex{ .pos = [2]f32{ 100, 100 }, .color = [4]f32{ 1, 0, 0, 1 } },
        Vertex{ .pos = [2]f32{ 500, 100 }, .color = [4]f32{ 0, 1, 0, 1 } },
        Vertex{ .pos = [2]f32{ 500, 500 }, .color = [4]f32{ 0, 0, 1, 1 } },
        Vertex{ .pos = [2]f32{ 100, 500 }, .color = [4]f32{ 1, 0, 1, 1 } },
    };
    vertices = vert[0..];

    var ind = [_]u16{ 0, 1, 2, 2, 3, 0 };
    indices = ind[0..];

    try createVertexBuffer();
    try createIndexBuffer();
}

pub fn deinit() void {
    c.vmaDestroyBuffer(allocator.allocator, vertex_buffer, vertex_buffer_alloc);
    c.vmaDestroyBuffer(allocator.allocator, index_buffer, index_buffer_alloc);
}
