const std = @import("std");

const skia = @import("skia-zig");
pub usingnamespace skia;

const c = @import("c.zig");

const window = @import("window.zig");

var interface: ?*const skia.gr_glinterface_t = undefined;
var context: ?*skia.gr_direct_context_t = undefined;
var backendRenderTarget: ?*skia.gr_backendrendertarget_t = undefined;

var surface: ?*skia.sk_surface_t = undefined;
var canvas: ?*skia.sk_canvas_t = undefined;

pub fn init() !void {
    interface = skia.gr_glinterface_create_native_interface() orelse return error.SkiaInterfaceInvalid;
    context = skia.gr_direct_context_make_gl(interface) orelse return error.SkiaCreateContextFailed;

    const gl_info = skia.gr_gl_framebufferinfo_t{
        .fFBOID = 0,
        .fFormat = c.GL_RGBA8,
    };

    const samples: c_int = 0;
    const stencil_bits: c_int = 8;

    const size = window.getSize();

    backendRenderTarget = skia.gr_backendrendertarget_new_gl(size.x, size.y, samples, stencil_bits, &gl_info) orelse return error.SkiaCreateRenderTargetFailed;

    const color_type = skia.RGBA_8888_SK_COLORTYPE;
    surface = skia.sk_surface_new_backend_render_target(@ptrCast(context), backendRenderTarget, skia.BOTTOM_LEFT_GR_SURFACE_ORIGIN, color_type, null, null) orelse return error.SkiaCreateSurfaceFailed;

    canvas = skia.sk_surface_get_canvas(surface) orelse unreachable;
}

pub fn deinit() void {
    skia.sk_surface_unref(surface);
    skia.gr_direct_context_free_gpu_resources(context);
    skia.gr_glinterface_unref(interface);
}

pub fn draw() void {
    skia.gr_direct_context_flush(context);
    skia.sk_canvas_clear(canvas, 0xffffffff);
}

pub fn getNative() ?*skia.sk_canvas_t {
    return canvas;
}
