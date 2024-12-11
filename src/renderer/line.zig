//! Line drawable struct

const std = @import("std");
const zmath = @import("zmath");

const shape = @import("root").renderer.shape;
const vulkan = @import("root").renderer.vulkan;

pub const Line = struct {
    shape: shape.ShapeIndexed,

    p1: zmath.F32x4,
    p2: zmath.F32x4,

    thickness: f32,
    color: zmath.F32x4,

    pub fn init(self: *Line, p1: zmath.F32x4, p2: zmath.F32x4, thickness: f32, color: zmath.F32x4) !void {
        self.thickness = thickness;
        self.color = color;
        self.p1 = p1;
        self.p2 = p2;

        try self.genShape();
    }

    pub fn deinit(self: Line) void {
        self.shape.deinit();
    }

    pub fn draw(self: Line) void {
        self.shape.draw();
    }

    pub fn update(self: *Line) !void {
        self.shape.deinit();
        try self.genShape();
    }

    fn genShape(self: *Line) !void {
        // const direction = zmath.normalize2(self.p2 - self.p1);
        // const perp = zmath.f32x4s(self.thickness / 2) * zmath.f32x4(-direction[1], direction[0], direction[2], 0);
        // var vertices = [_]vulkan.vertex_buffer.Vertex{
        //     vulkan.vertex_buffer.Vertex{ .pos = self.p1 + perp },
        //     vulkan.vertex_buffer.Vertex{ .pos = self.p1 - perp },
        //     vulkan.vertex_buffer.Vertex{ .pos = self.p2 - perp },
        //     vulkan.vertex_buffer.Vertex{ .pos = self.p2 + perp },
        // };

        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(-0.5, -0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(0.5, -0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(0.5, 0.5, 0, 1) },
            vulkan.vertex_buffer.Vertex{ .pos = zmath.f32x4(-0.5, 0.5, 0, 1) },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        const vec = self.p1 - self.p2;
        const length = zmath.length2(vec)[0];
        const angle = std.math.atan2(vec[1], vec[0]);

        var model = zmath.identity();
        model = zmath.mul(model, zmath.scaling(length, self.thickness, 1.0));
        model = zmath.mul(model, zmath.translation(length / 2, 0.0, 0.0));
        model = zmath.mul(model, zmath.rotationZ(angle - std.math.pi));
        model = zmath.mul(model, zmath.translationV(self.p1));

        var instance = shape.InstanceData{
            .model = model,
            .color = self.color,
        };

        try self.shape.init(&vertices, &indices, &instance);
    }
};
