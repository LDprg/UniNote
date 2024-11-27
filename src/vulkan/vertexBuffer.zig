const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const physicalDevice = @import("physicalDevice.zig");
const queue = @import("queue.zig");
const queueFamily = @import("queueFamily.zig");
const renderPass = @import("renderPass.zig");
const frameBuffer = @import("frameBuffer.zig");
const swapChain = @import("swapChain.zig");
const commandBuffer = @import("commandBuffer.zig");

pub var vertexBuffer: c.VkBuffer = undefined;
pub var vertexBufferMemory: c.VkDeviceMemory = undefined;
pub var indexBuffer: c.VkBuffer = undefined;
pub var indexBufferMemory: c.VkDeviceMemory = undefined;

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

fn findMemoryType(typeFilter: u32, properties: c.VkMemoryPropertyFlags) !u32 {
    var memProperties: c.VkPhysicalDeviceMemoryProperties = undefined;
    c.vkGetPhysicalDeviceMemoryProperties(physicalDevice.physicalDevice, &memProperties);

    for (0..memProperties.memoryTypeCount) |i| {
        if ((typeFilter & (@as(u32, 1) << @intCast(i))) != 0 and (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
            return @intCast(i);
        }
    }

    try std.debug.panic("", .{});
}

fn createBuffer(size: c.VkDeviceSize, usage: c.VkBufferUsageFlags, properties: c.VkMemoryPropertyFlags, buffer: *c.VkBuffer, bufferMemory: *c.VkDeviceMemory) !void {
    const bufferInfo = c.VkBufferCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = size,
        .usage = usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    try util.check_vk(c.vkCreateBuffer(device.device, &bufferInfo, null, buffer));

    var memRequirements: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(device.device, buffer.*, &memRequirements);

    const allocInfo = c.VkMemoryAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memRequirements.size,
        .memoryTypeIndex = try findMemoryType(memRequirements.memoryTypeBits, properties),
    };

    try util.check_vk(c.vkAllocateMemory(device.device, &allocInfo, null, bufferMemory));

    try util.check_vk(c.vkBindBufferMemory(device.device, buffer.*, bufferMemory.*, 0));
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
    const bufferSize: c.VkDeviceSize = @sizeOf(@TypeOf(vertices[0])) * vertices.len;

    var stagingBuffer: c.VkBuffer = undefined;
    var stagingBufferMemory: c.VkDeviceMemory = undefined;
    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &stagingBuffer, &stagingBufferMemory);

    var data: ?*anyopaque = null;
    try util.check_vk(c.vkMapMemory(device.device, stagingBufferMemory, 0, bufferSize, 0, @ptrCast(&data)));
    @memcpy(@as([*]Vertex, @ptrCast(@alignCast(data))), vertices);
    c.vkUnmapMemory(device.device, stagingBufferMemory);

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &vertexBuffer, &vertexBufferMemory);

    try copyBuffer(stagingBuffer, vertexBuffer, bufferSize);

    c.vkDestroyBuffer(device.device, stagingBuffer, null);
    c.vkFreeMemory(device.device, stagingBufferMemory, null);
}

fn createIndexBuffer() !void {
    const bufferSize: c.VkDeviceSize = @sizeOf(@TypeOf(indices[0])) * indices.len;

    var stagingBuffer: c.VkBuffer = undefined;
    var stagingBufferMemory: c.VkDeviceMemory = undefined;
    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, &stagingBuffer, &stagingBufferMemory);

    var data: ?*anyopaque = null;
    try util.check_vk(c.vkMapMemory(device.device, stagingBufferMemory, 0, bufferSize, 0, @ptrCast(&data)));
    @memcpy(@as([*]u16, @ptrCast(@alignCast(data))), indices);
    c.vkUnmapMemory(device.device, stagingBufferMemory);

    try createBuffer(bufferSize, c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &indexBuffer, &indexBufferMemory);

    try copyBuffer(stagingBuffer, indexBuffer, bufferSize);

    c.vkDestroyBuffer(device.device, stagingBuffer, null);
    c.vkFreeMemory(device.device, stagingBufferMemory, null);
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
    c.vkDestroyBuffer(device.device, indexBuffer, null);
    c.vkFreeMemory(device.device, indexBufferMemory, null);

    c.vkDestroyBuffer(device.device, vertexBuffer, null);
    c.vkFreeMemory(device.device, vertexBufferMemory, null);
}
