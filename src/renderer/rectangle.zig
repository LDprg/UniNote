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

    pub fn init(self: *Rectangle, size: zmath.F32x4, pos: zmath.F32x4, color: zmath.F32x4) !void {
        self.size = size;
        self.pos = pos;
        self.color = color;

        try self.genShape();
    }

    pub fn deinit(self: Rectangle) void {
        self.shape.deinit();
    }

    /// Update verticies (needed to apply any changes)
    pub fn update(self: *Rectangle) !void {
        self.deinit();
        try self.genShape();
    }

    pub fn draw(self: Rectangle) void {
        self.shape.draw();
    }

    fn genShape(self: *Rectangle) !void {
        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(-0.5, -0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(0.5, -0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(0.5, 0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(-0.5, 0.5, 0, 1) },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        var model = zmath.identity();
        model = zmath.mul(model, zmath.scalingV(self.size));
        // model = zmath.mul(model, zmath.rotationZ(std.math.pi / 4.0));
        model = zmath.mul(model, zmath.translationV(self.pos));
        model = zmath.mul(model, zmath.translationV(self.size / zmath.f32x4s(2)));
        var instance = shape.InstanceData{
            .model = model,
            .color = self.color,
        };

        try self.shape.init(&vertices, &indices, &instance);
    }
};
