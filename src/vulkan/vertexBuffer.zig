const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");
const physicalDevice = @import("physicalDevice.zig");
const queueFamily = @import("queueFamily.zig");
const renderPass = @import("renderPass.zig");
const frameBuffer = @import("frameBuffer.zig");
const swapChain = @import("swapChain.zig");

pub var vertexBuffer: c.VkBuffer = undefined;
pub var vertexBufferMemory: c.VkDeviceMemory = undefined;

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

pub fn init(alloc: std.mem.Allocator) !void {
    vertices = try alloc.alloc(Vertex, 3);
    vertices[0] = Vertex{ .pos = [2]f32{ 0, -0.5 }, .color = [4]f32{ 1, 0, 0, 1 } };
    vertices[1] = Vertex{ .pos = [2]f32{ 0.5, 0.5 }, .color = [4]f32{ 0, 1, 0, 1 } };
    vertices[2] = Vertex{ .pos = [2]f32{ -0.5, 0.5 }, .color = [4]f32{ 0, 0, 1, 1 } };

    const bufferInfo = c.VkBufferCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = @sizeOf(Vertex) * vertices.len,
        .usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    };

    try util.check_vk(c.vkCreateBuffer(device.device, &bufferInfo, null, &vertexBuffer));

    var memRequirements: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(device.device, vertexBuffer, &memRequirements);

    const allocInfo = c.VkMemoryAllocateInfo{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memRequirements.size,
        .memoryTypeIndex = try findMemoryType(memRequirements.memoryTypeBits, c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    };

    try util.check_vk(c.vkAllocateMemory(device.device, &allocInfo, null, &vertexBufferMemory));

    try util.check_vk(c.vkBindBufferMemory(device.device, vertexBuffer, vertexBufferMemory, 0));

    var data: ?*anyopaque = null;
    try util.check_vk(c.vkMapMemory(device.device, vertexBufferMemory, 0, bufferInfo.size, 0, @ptrCast(&data)));
    @memcpy(@as([*]Vertex, @ptrCast(@alignCast(data))), vertices);
    c.vkUnmapMemory(device.device, vertexBufferMemory);
}

pub fn deinit() void {
    c.vkDestroyBuffer(device.device, vertexBuffer, null);

    c.vkDestroyBuffer(device.device, vertexBuffer, null);
    c.vkFreeMemory(device.device, vertexBufferMemory, null);
}
