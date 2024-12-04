const std = @import("std");

const c = @import("root").c;

const allocator = @import("root").renderer.vulkan.allocator;
const command_buffer = @import("root").renderer.vulkan.command_buffer;
const device = @import("root").renderer.vulkan.device;
const frame_buffer = @import("root").renderer.vulkan.frame_buffer;
const physical_device = @import("root").renderer.vulkan.physical_device;
const queue = @import("root").renderer.vulkan.queue;
const queue_family = @import("root").renderer.vulkan.queue_family;
const render_pass = @import("root").renderer.vulkan.render_pass;
const swapchain = @import("root").renderer.vulkan.swapchain;
const util = @import("root").renderer.vulkan.util;

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

pub const Buffer = struct {
    buffer: c.VkBuffer,
    buffer_alloc: c.VmaAllocation,
    buffer_alloc_info: ?c.VmaAllocationInfo,
};

pub var vertex_buffer: Buffer = undefined;
pub var index_buffer: Buffer = undefined;

pub fn init(vertices: []Vertex, indices: []u16) !void {
    try createBufferStaging(&vertex_buffer, Vertex, vertices, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
    try createBufferStaging(&index_buffer, u16, indices, c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT);
}

pub fn deinit() void {
    c.vmaDestroyBuffer(allocator.allocator, vertex_buffer.buffer, vertex_buffer.buffer_alloc);
    c.vmaDestroyBuffer(allocator.allocator, index_buffer.buffer, index_buffer.buffer_alloc);
}

fn createBufferStaging(buffer: *Buffer, comptime result_type: type, result: []result_type, flags: c.VmaAllocationCreateFlags) !void {
    const size: c.VkDeviceSize = @sizeOf(result_type) * result.len;

    var staging_buffer = Buffer{
        .buffer = null,
        .buffer_alloc = null,
        .buffer_alloc_info = c.VmaAllocationInfo{},
    };

    try createBuffer(
        size,
        c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        c.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | c.VMA_ALLOCATION_CREATE_MAPPED_BIT,
        &staging_buffer,
    );

    @memcpy(@as([*]result_type, @ptrCast(@alignCast(staging_buffer.buffer_alloc_info.?.pMappedData))), result);

    try createBuffer(
        size,
        @as(u32, @intCast(c.VK_BUFFER_USAGE_TRANSFER_DST_BIT)) | flags,
        0,
        buffer,
    );

    try copyBuffer(staging_buffer.buffer, buffer.buffer, size);

    c.vmaDestroyBuffer(allocator.allocator, staging_buffer.buffer, staging_buffer.buffer_alloc);
}

pub fn createBuffer(
    size: c.VkDeviceSize,
    usage: c.VkBufferUsageFlags,
    flags: c.VmaAllocationCreateFlags,
    buffer: *Buffer,
) !void {
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

    try util.check_vk(c.vmaCreateBuffer(
        allocator.allocator,
        &buffer_info,
        &alloc_create_info,
        &buffer.buffer,
        &buffer.buffer_alloc,
        if (buffer.buffer_alloc_info != null) &buffer.buffer_alloc_info.? else null,
    ));
}

fn copyBuffer(src_buffer: c.VkBuffer, dst_buffer: c.VkBuffer, size: c.VkDeviceSize) !void {
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
    c.vkCmdCopyBuffer(cmdbuff, src_buffer, dst_buffer, 1, &copy_region);

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
