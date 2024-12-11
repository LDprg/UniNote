const std = @import("std");
const zmath = @import("zmath");

const c = @import("root").c;

const vulkan = @import("root").renderer.vulkan;

const allocator = vulkan.allocator;
const command_buffer = vulkan.command_buffer;
const descriptor_sets = vulkan.descriptor_sets;
const device = vulkan.device;
const pipeline = vulkan.pipeline;
const swapchain = vulkan.swapchain;
const vertex_buffer = vulkan.vertex_buffer;

pub const InstanceData = struct {
    model: zmath.Mat,
    color: zmath.F32x4,

    pub fn getBindingDescription() c.VkVertexInputBindingDescription {
        return c.VkVertexInputBindingDescription{
            .binding = 1,
            .stride = @sizeOf(InstanceData),
            .inputRate = c.VK_VERTEX_INPUT_RATE_INSTANCE,
        };
    }
    pub fn getAttributeDescriptions(alloc: std.mem.Allocator) ![]c.VkVertexInputAttributeDescription {
        const attribute_descriptions = try alloc.alloc(c.VkVertexInputAttributeDescription, 5);
        for (0..4) |i| {
            attribute_descriptions[i] = .{
                .binding = 1,
                .location = 10 + @as(u32, @intCast(i)),
                .format = c.VK_FORMAT_R32G32B32A32_SFLOAT,
                .offset = @offsetOf(InstanceData, "model") + @as(u32, @intCast(i)) * @sizeOf(zmath.F32x4),
            };
        }

        attribute_descriptions[4] = .{
            .binding = 1,
            .location = 15,
            .format = c.VK_FORMAT_R32G32B32A32_SFLOAT,
            .offset = @offsetOf(InstanceData, "color"),
        };

        return attribute_descriptions;
    }
};

pub const ShapeIndexed = struct {
    instance: *InstanceData,
    indices: []u16,
    vertices: []vertex_buffer.Vertex,

    index_buffer: vertex_buffer.Buffer,
    instance_buffer: vertex_buffer.Buffer,
    vertex_buffer: vertex_buffer.Buffer,

    pub fn init(self: *ShapeIndexed, vertices: []vertex_buffer.Vertex, indices: []u16, instance: *InstanceData) !void {
        self.indices = indices;
        self.instance = instance;
        self.vertices = vertices;

        var inst = [_]InstanceData{self.instance.*};
        try vertex_buffer.createBufferStaging(&self.instance_buffer, InstanceData, &inst, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);

        try vertex_buffer.createBufferStaging(&self.index_buffer, u16, self.indices, c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT);
        try vertex_buffer.createBufferStaging(&self.vertex_buffer, vertex_buffer.Vertex, self.vertices, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
    }

    pub fn deinit(self: ShapeIndexed) void {
        _ = c.vkDeviceWaitIdle(device.device);

        c.vmaDestroyBuffer(allocator.allocator, self.instance_buffer.buffer, self.instance_buffer.buffer_alloc);
        c.vmaDestroyBuffer(allocator.allocator, self.vertex_buffer.buffer, self.vertex_buffer.buffer_alloc);
        c.vmaDestroyBuffer(allocator.allocator, self.index_buffer.buffer, self.index_buffer.buffer_alloc);
    }

    pub fn draw(self: ShapeIndexed) void {
        if (!vulkan.swapchain_rebuild) {
            const offsets: [*]const c.VkDeviceSize = &.{0};

            const vertex_buffers: [*]const c.VkBuffer = &.{self.vertex_buffer.buffer};
            c.vkCmdBindVertexBuffers(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                vertex_buffers,
                offsets,
            );

            const instance_buffers: [*]const c.VkBuffer = &.{self.instance_buffer.buffer};
            c.vkCmdBindVertexBuffers(
                command_buffer.command_buffers[vulkan.current_frame],
                1,
                1,
                instance_buffers,
                offsets,
            );

            c.vkCmdBindIndexBuffer(
                command_buffer.command_buffers[vulkan.current_frame],
                self.index_buffer.buffer,
                0,
                c.VK_INDEX_TYPE_UINT16,
            );

            const viewport = c.VkViewport{
                .x = 0.0,
                .y = 0.0,
                .width = @floatFromInt(swapchain.extent.width),
                .height = @floatFromInt(swapchain.extent.height),
                .minDepth = 0.0,
                .maxDepth = 1.0,
            };
            c.vkCmdSetViewport(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                &viewport,
            );

            const scissor = c.VkRect2D{
                .offset = .{ .x = 0, .y = 0 },
                .extent = swapchain.extent,
            };
            c.vkCmdSetScissor(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                &scissor,
            );

            c.vkCmdBindDescriptorSets(
                command_buffer.command_buffers[vulkan.current_frame],
                c.VK_PIPELINE_BIND_POINT_GRAPHICS,
                pipeline.pipeline_layout,
                0,
                1,
                &descriptor_sets.descriptor_sets[vulkan.current_frame],
                0,
                null,
            );

            c.vkCmdDrawIndexed(command_buffer.command_buffers[vulkan.current_frame], @intCast(self.indices.len), 1, 0, 0, 0);
        }
    }
};

pub const Shape = struct {
    vertices: []vertex_buffer.Vertex,
    vertex_buffer: vertex_buffer.Buffer,

    pub fn init(self: *Shape, vertices: []vertex_buffer.Vertex) !void {
        self.vertices = vertices;

        try vertex_buffer.createBufferStaging(&self.vertex_buffer, vertex_buffer.Vertex, self.vertices, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
    }

    pub fn deinit(self: Shape) void {
        _ = c.vkDeviceWaitIdle(device.device);

        c.vmaDestroyBuffer(allocator.allocator, self.vertex_buffer.buffer, self.vertex_buffer.buffer_alloc);
    }

    pub fn draw(self: Shape) void {
        if (!vulkan.swapchain_rebuild) {
            const vertex_buffers: [*]const c.VkBuffer = &.{self.vertex_buffer.buffer};
            const offsets: [*]const c.VkDeviceSize = &.{0};
            c.vkCmdBindVertexBuffers(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                vertex_buffers,
                offsets,
            );

            const viewport = c.VkViewport{
                .x = 0.0,
                .y = 0.0,
                .width = @floatFromInt(swapchain.extent.width),
                .height = @floatFromInt(swapchain.extent.height),
                .minDepth = 0.0,
                .maxDepth = 1.0,
            };
            c.vkCmdSetViewport(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                &viewport,
            );

            const scissor = c.VkRect2D{
                .offset = .{ .x = 0, .y = 0 },
                .extent = swapchain.extent,
            };
            c.vkCmdSetScissor(
                command_buffer.command_buffers[vulkan.current_frame],
                0,
                1,
                &scissor,
            );

            c.vkCmdBindDescriptorSets(
                command_buffer.command_buffers[vulkan.current_frame],
                c.VK_PIPELINE_BIND_POINT_GRAPHICS,
                pipeline.pipeline_layout,
                0,
                1,
                &descriptor_sets.descriptor_sets[vulkan.current_frame],
                0,
                null,
            );

            c.vkCmdDraw(command_buffer.command_buffers[vulkan.current_frame], @intCast(self.vertices.len), 1, 0, 0);
        }
    }
};
