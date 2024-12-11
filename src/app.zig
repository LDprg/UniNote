//! Main programm
//! Here is the actual program doing stuff

const std = @import("std");

const zmath = @import("zmath");

const c = @import("root").c;

const event = @import("root").core.event;
const window = @import("root").core.window;
const application = @import("root").core.application;

const protobuf = @import("root").file.protobuf;

const imgui = @import("root").renderer.imgui;
const vulkan = @import("root").renderer.vulkan;
const shape = @import("root").renderer.shape;
const rectangle = @import("root").renderer.rectangle;
const line = @import("root").renderer.line;

var x: f32 = 0;
var y: f32 = 0;

var alloc: std.mem.Allocator = undefined;

var test_rectangle: rectangle.Rectangle = undefined;
var test_line: line.Line = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    std.log.info("Init app", .{});

    alloc = alloc_root;

    try test_rectangle.init(zmath.f32x4(500, 500, 0, 1), zmath.f32x4(200, 200, 0, 1), zmath.f32x4(1, 0, 0, 1));
    try test_line.init(zmath.f32x4(100, 100, 0, 1), zmath.f32x4(500, 500, 0, 1), 5, zmath.f32x4(0, 1, 0, 1));
}

pub fn deinit() void {
    std.log.info("Deinit app", .{});

    test_line.deinit();
    test_rectangle.deinit();
}

pub fn processEvent(e: *const c.SDL_Event) !void {
    switch (event.fromSDL(e)) {
        event.Event.quit => application.close(),
        event.Event.mouse_button_down, event.Event.pen_down => {
            x = e.ptouch.x;
            y = e.ptouch.y;

            test_line.p2 = zmath.f32x4(x, y, 0, 1);
            try test_line.update();
            // test_rectangle.pos = zmath.f32x4(x, y, 0, 1);
            // try test_rectangle.update();
        },
        else => {},
    }
}

pub fn update() !void {
    // if (c.igBeginMainMenuBar()) {
    //     defer c.igEndMainMenuBar();

    //     if (c.igBeginMenu("File", true)) {
    //         defer c.igEndMenu();

    //         if (c.igMenuItem_Bool("Save", "", false, true)) {
    //             std.log.debug("Save: {}", .{vulkan.swapchain.extent});
    //         }
    //         if (c.igMenuItem_Bool("Open", "", false, true)) {
    //             std.log.debug("Open", .{});
    //         }
    //     }
    // }

    // c.igShowDemoWindow(null);
}

pub fn draw() !void {
    test_rectangle.draw();
    test_line.draw();
}
