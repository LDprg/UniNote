//! root source file just all modules and the main loop

const std = @import("std");

pub const c = @import("c.zig");

pub const app = @import("app.zig");

pub const file = @import("file/file.zig");
pub const renderer = @import("renderer/renderer.zig");
pub const core = @import("core/core.zig");

/// Main Loop
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) std.debug.panic("Leaks deteced!", .{});
    }

    const alloc = gpa.allocator();

    try core.application.run(alloc);
}
