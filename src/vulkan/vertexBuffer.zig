const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const allocator = @import("allocator.zig");
const device = @import("device.zig");
const physicalDevice = @import("physicalDevice.zig");
const queue = @import("queue.zig");
const queueFamily = @import("queueFamily.zig");
const renderPass = @import("renderPass.zig");
const frameBuffer = @import("frameBuffer.zig");
const swapChain = @import("swapChain.zig");
const commandBuffer = @import("commandBuffer.zig");

pub var vertexBuffer: c.VkBuffer = undefined;
pub var vertexBufferAlloc: c.VmaAllocation = undefined;

pub var indexBuffer: c.VkBuffer = undefined;
pub var indexBufferAlloc: c.VmaAllocation = undefined;

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
        const attributeDescriptions = try alloc.alloc(c.VkVertexInputAttributeDescription, 2);
        attributeDescriptions[0] = .{
            .binding = 0,
            .location = 0,
            .format = c.VK_FORMAT_R32G32_SFLOAT,
            .offset = @offsetOf(Vertex, "pos"),
        };
        attributeDescriptions[1] = .{
            .binding = 0,
            .location = 1,
            .format = c.VK_FORMAT_R32G32B32A32_SFLOAT,
            .offset = @offsetOf(Vertex, "color"),
        };

        return attributeDescriptions;
    }
};

pub var vertices: []Vertex = undefined;
pub var indices: []u16 = undefined;

fn createBuffer(size: c.VkDeviceSize, usage: c.VkBufferUsageFlags, flags: c.VmaAllocationCreateFlags, buffer: *c.VkBuffer, bufferAlloc: *c.VmaAllocation, bufferAllocInfo: ?*c.VmaAllocationInfo) !void {
    const bufferInfo = c.VkBufferCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = size,
        .usage = usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    const allocCreateInfo = c.VmaAllocationCreateInfo{
        .usage = c.VMA_MEMORY_USAGE_AUTO,
        .flags = flags,
    };

    try util.check_vk(c.vmaCreateBuffer(allocator.allocator, &bufferInfo, &allocCreateInfo, buffer, bufferAlloc, bufferAllocInfo));
}

fn copyBuffer(srcBuffer: c.VkBuffer, dstBuffer: c.VkBuffer, size: c.VkDeviceSize) !void {
    const allocInfo = c.VkCommandBufferAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandPool = commandBuffer.commandPool,
        .commandBufferCount = 1,
    };

    var cmdbuff: c.VkCommandBuffer = undefined;
    try util.check_vk(c.vkAllocateCommandBuffers(device.device, &allocInfo, &cmdbuff));

    var beginInfo = c.VkCommandBufferBeginInfo{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };

    try util.check_vk(c.vkBeginCommandBuffer(cmdbuff, &beginInfo));

    const copyRegion = c.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = size,
    };
    c.vkCmdCopyBuffer(cmdbuff, srcBuffer, dstBuffer, 1, &copyRegion);

    try util.check_vk(c.vkEndCommandBuffer(cmdbuff));

    const submitInfo = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &cmdbuff,
    };

    try util.check_vk(c.vkQueueSubmit(queue.graphicsQueue, 1, &submitInfo, null));
    try util.check_vk(c.vkQueueWaitIdle(queue.graphicsQueue));

    c.vkFreeCommandBuffers(device.device, commandBuffer.commandPool, 1, &cmdbuff);
}

fn createVertexBuffer() !void {
    const bufferSize: c.VkDeviceSize = @sizeOf(Vertex) * vertices.len;

    var stagingBuffer: c.VkBuffer = null;
    var stagingBufferAlloc: c.VmaAllocation = null;
    var stagingBufferAllocInfo = c.VmaAllocationInfo{};

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT, &stagingBuffer, &stagingBufferAlloc, &stagingBufferAllocInfo);

    @memcpy(@as([*]Vertex, @ptrCast(@alignCast(stagingBufferAllocInfo.pMappedData))), vertices);

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, 0, &vertexBuffer, &vertexBufferAlloc, null);

    try copyBuffer(stagingBuffer, vertexBuffer, bufferSize);

    c.vmaDestroyBuffer(allocator.allocator, stagingBuffer, stagingBufferAlloc);
}

fn createIndexBuffer() !void {
    const bufferSize: c.VkDeviceSize = @sizeOf(Vertex) * vertices.len;

    var stagingBuffer: c.VkBuffer = null;
    var stagingBufferAlloc: c.VmaAllocation = null;
    var stagingBufferAllocInfo = c.VmaAllocationInfo{};

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT, &stagingBuffer, &stagingBufferAlloc, &stagingBufferAllocInfo);

    @memcpy(@as([*]u16, @ptrCast(@alignCast(stagingBufferAllocInfo.pMappedData))), indices);

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, 0, &indexBuffer, &indexBufferAlloc, null);

    try copyBuffer(stagingBuffer, indexBuffer, bufferSize);

    c.vmaDestroyBuffer(allocator.allocator, stagingBuffer, stagingBufferAlloc);
}

pub fn init(_: std.mem.Allocator) !void {
    var vert = [_]Vertex{
        Vertex{ .pos = [2]f32{ -0.5, -0.5 }, .color = [4]f32{ 1, 0, 0, 1 } },
        Vertex{ .pos = [2]f32{ 0.5, -0.5 }, .color = [4]f32{ 0, 1, 0, 1 } },
        Vertex{ .pos = [2]f32{ 0.5, 0.5 }, .color = [4]f32{ 0, 0, 1, 1 } },
        Vertex{ .pos = [2]f32{ -0.5, 0.5 }, .color = [4]f32{ 1, 0, 1, 1 } },
    };
    vertices = vert[0..];

    var ind = [_]u16{ 0, 1, 2, 2, 3, 0 };
    indices = ind[0..];

    try createVertexBuffer();
    try createIndexBuffer();
}

pub fn deinit() void {
    c.vmaDestroyBuffer(allocator.allocator, vertexBuffer, vertexBufferAlloc);
    c.vmaDestroyBuffer(allocator.allocator, indexBuffer, indexBufferAlloc);
}
