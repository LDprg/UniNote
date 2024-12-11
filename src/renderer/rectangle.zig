//! Rectangle drawable struct

const std = @import("std");
const zmath = @import("zmath");

const c = @import("root").c;

const allocator = @import("root").renderer.vulkan.allocator;
const command_buffer = @import("root").renderer.vulkan.command_buffer;
const device = @import("root").renderer.vulkan.device;
const vertex_buffer = @import("root").renderer.vulkan.vertex_buffer;

const shape = @import("root").renderer.shape;
const vulkan = @import("root").renderer.vulkan;

pub const InstanceData = struct {
    color: zmath.F32x4,

    pub fn getBindingDescription() c.VkVertexInputBindingDescription {
        return c.VkVertexInputBindingDescription{
            .binding = 1,
            .stride = @sizeOf(InstanceData),
            .inputRate = c.VK_VERTEX_INPUT_RATE_INSTANCE,
        };
    }
    pub fn getAttributeDescriptions(alloc: std.mem.Allocator) ![]c.VkVertexInputAttributeDescription {
        const attribute_descriptions = try alloc.alloc(c.VkVertexInputAttributeDescription, 1);
        attribute_descriptions[0] = .{
            .binding = 1,
            .location = 1,
            .format = c.VK_FORMAT_R32G32B32A32_SFLOAT,
            .offset = @offsetOf(InstanceData, "color"),
        };

        return attribute_descriptions;
    }
};

pub const Rectangle = struct {
    /// Contains verticies and indicies of the Rectangle
    shape: shape.ShapeIndexed,

    /// Size in XYZW
    /// Z & W will be ignored
    /// this is only a vec4 for SIMD
    size: zmath.F32x4,

    /// Position in XYZW
    /// Z is the z-index of the rectangle
    /// W should be set to 1
    /// this is only a vec4 for SIMD
    pos: zmath.F32x4,

    /// Color in RGBA format
    color: zmath.F32x4,

    instance_buffer: vertex_buffer.Buffer,
    instance_data: InstanceData,

    pub fn init(self: *Rectangle, size: zmath.F32x4, pos: zmath.F32x4, color: zmath.F32x4) !void {
        self.size = size;
        self.pos = pos;
        self.color = color;

        try self.genShape();
    }

    pub fn deinit(self: Rectangle) void {
        _ = c.vkDeviceWaitIdle(device.device);

        c.vmaDestroyBuffer(allocator.allocator, self.instance_buffer.buffer, self.instance_buffer.buffer_alloc);
        self.shape.deinit();
    }

    /// Update verticies (needed to apply any changes)
    pub fn update(self: *Rectangle) !void {
        self.deinit();
        try self.genShape();
    }

    pub fn draw(self: Rectangle) void {
        const offsets: [*]const c.VkDeviceSize = &.{0};

        const instance_buffers: [*]const c.VkBuffer = &.{self.instance_buffer.buffer};
        c.vkCmdBindVertexBuffers(
            command_buffer.command_buffers[vulkan.current_frame],
            1,
            1,
            instance_buffers,
            offsets,
        );

        self.shape.draw();
    }

    fn genShape(self: *Rectangle) !void {
        const top_right = self.pos;
        const top_left = zmath.mulAdd(zmath.f32x4(1, 0, 0, 0), self.size, self.pos);
        const bottom_left = zmath.mulAdd(zmath.f32x4(1, 1, 0, 0), self.size, self.pos);
        const bottom_rigth = zmath.mulAdd(zmath.f32x4(0, 1, 0, 0), self.size, self.pos);

        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = top_right },
            vulkan.vertex_buffer.Vertex{ .pos = top_left },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_left },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_rigth },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        var instance = [_]InstanceData{
            InstanceData{
                .color = self.color,
            },
        };

        try vertex_buffer.createBufferStaging(&self.instance_buffer, InstanceData, &instance, c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);
        try self.shape.init(&vertices, &indices);
    }
};
