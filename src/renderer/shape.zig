const c = @import("root").c;

const vulkan = @import("root").renderer.vulkan;

const allocator = vulkan.allocator;
const command_buffer = vulkan.command_buffer;
const descriptor_sets = vulkan.descriptor_sets;
const device = vulkan.device;
const pipeline = vulkan.pipeline;
const swapchain = vulkan.swapchain;
const vertex_buffer = vulkan.vertex_buffer;

pub const ShapeIndexed = struct {
    vertices: []vertex_buffer.Vertex,
    indices: []u16,
    vertex_buffer: vertex_buffer.Buffer,
    index_buffer: vertex_buffer.Buffer,

    pub fn init(self: *ShapeIndexed, vertices: []vertex_buffer.Vertex, indices: []u16) !void {
        self.vertices = vertices;
        self.indices = indices;

        try vertex_buffer.createBufferStaging(&self.vertex_buffer, vertex_buffer.Vertex, self.vertices, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
        try vertex_buffer.createBufferStaging(&self.index_buffer, u16, self.indices, c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT);
    }

    pub fn deinit(self: ShapeIndexed) void {
        _ = c.vkDeviceWaitIdle(device.device);

        c.vmaDestroyBuffer(allocator.allocator, self.vertex_buffer.buffer, self.vertex_buffer.buffer_alloc);
        c.vmaDestroyBuffer(allocator.allocator, self.index_buffer.buffer, self.index_buffer.buffer_alloc);
    }

    pub fn draw(self: ShapeIndexed) void {
        const vertex_buffers: [*]const c.VkBuffer = &.{self.vertex_buffer.buffer};
        const offsets: [*]const c.VkDeviceSize = &.{0};
        c.vkCmdBindVertexBuffers(
            command_buffer.command_buffers[vulkan.current_frame],
            0,
            1,
            vertex_buffers,
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
};
