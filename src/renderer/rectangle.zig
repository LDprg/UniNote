//! Rectangle drawable struct

const zmath = @import("zmath");

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

        const top_right = self.pos;
        const top_left = zmath.mulAdd(zmath.f32x4(1, 0, 0, 0), self.size, self.pos);
        const bottom_left = zmath.mulAdd(zmath.f32x4(1, 1, 0, 0), self.size, self.pos);
        const bottom_rigth = zmath.mulAdd(zmath.f32x4(0, 1, 0, 0), self.size, self.pos);

        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = top_right, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = top_left, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_left, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_rigth, .color = self.color },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        try self.shape.init(&vertices, &indices);
    }

    pub fn deinit(self: Rectangle) void {
        self.shape.deinit();
    }

    /// Update verticies (needed to apply any changes)
    pub fn update(self: *Rectangle) !void {
        const top_right = self.pos;
        const top_left = zmath.mulAdd(zmath.f32x4(1, 0, 0, 0), self.size, self.pos);
        const bottom_left = zmath.mulAdd(zmath.f32x4(1, 1, 0, 0), self.size, self.pos);
        const bottom_rigth = zmath.mulAdd(zmath.f32x4(0, 1, 0, 0), self.size, self.pos);

        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = top_right, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = top_left, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_left, .color = self.color },
            vulkan.vertex_buffer.Vertex{ .pos = bottom_rigth, .color = self.color },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        self.shape.deinit();
        try self.shape.init(&vertices, &indices);
    }

    pub fn draw(self: Rectangle) void {
        self.shape.draw();
    }
};
