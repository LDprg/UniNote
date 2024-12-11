//! Line drawable struct

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
        const direction = zmath.normalize2(self.p2 - self.p1);
        const perp = zmath.f32x4s(self.thickness / 2) * zmath.f32x4(-direction[1], direction[0], direction[2], 0);
        var vertices = [_]vulkan.vertex_buffer.Vertex{
            vulkan.vertex_buffer.Vertex{ .pos = self.p1 + perp },
            vulkan.vertex_buffer.Vertex{ .pos = self.p1 - perp },
            vulkan.vertex_buffer.Vertex{ .pos = self.p2 - perp },
            vulkan.vertex_buffer.Vertex{ .pos = self.p2 + perp },
        };

        var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        var instance = shape.InstanceData{
            .color = self.color,
        };

        try self.shape.init(&vertices, &indices, &instance);
    }
};
