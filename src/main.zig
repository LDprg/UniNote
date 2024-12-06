//! UniNote is a note taking program for Students!
//! It focuses on high drawing performance and student related features.
//! To achieve this it uses SDL3 and VULKAN combined with ImGui
//! # WARNING
//! DO NOT USE THIS SOFTWARE IN PRODUCTION AND NOT EVEN ALPHA QUALITY
//! AND THERE IS NOTHING LIKE COMPATIBILITY EVEN BETWEEN MINOR VERSIONS

const std = @import("std");

// Include all modules so they can be accessed using: `@import("root")`
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
