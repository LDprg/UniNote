const std = @import("std");

const vulkan = @import("vulkan.zig");

const skia = @import("skia-zig");
pub usingnamespace skia;

const c = @import("c.zig");

const window = @import("window.zig");

var vkContext: skia.gr_vk_backendcontext_t = undefined;
var extensions: ?*skia.gr_vk_extensions_t = undefined;
var context: ?*skia.gr_direct_context_t = undefined;
var backendRenderTarget: ?*skia.gr_backendrendertarget_t = undefined;

var surface: ?*skia.sk_surface_t = undefined;
var canvas: ?*skia.sk_canvas_t = undefined;

pub fn init() !void {
    std.debug.print("Init Skia vulkan\n", .{});

    const getProc = struct {
        fn f(_: ?*anyopaque, proc_name: [*c]const u8, instance: ?*skia.vk_instance_t, device: ?*skia.vk_device_t) callconv(.C) skia.gr_vk_func_ptr {
            if (device != null) {
                return c.vkGetDeviceProcAddr(@as(c.VkDevice, @ptrCast(device)), proc_name);
            }
            return c.vkGetInstanceProcAddr(@as(c.VkInstance, @ptrCast(instance)), proc_name);
        }
    }.f;

    std.debug.print("Init extension\n", .{});

    extensions = skia.gr_vk_extensions_new();

    skia.gr_vk_extensions_init(
        extensions,
        getProc,
        null,
        @as(*skia.vk_instance_t, @ptrCast(vulkan.instance.instance)),
        @as(*skia.vk_physical_device_t, @ptrCast(vulkan.physicalDevice.physicalDevice)),
        @intCast(vulkan.instance.extensions.len),
        vulkan.instance.extensions.ptr,
        @intCast(vulkan.device.extensions.len),
        vulkan.device.extensions.ptr,
    );

    vkContext = skia.gr_vk_backendcontext_t{
        .fInstance = @as(*skia.vk_instance_t, @ptrCast(vulkan.instance.instance)),
        .fPhysicalDevice = @as(*skia.vk_physical_device_t, @ptrCast(vulkan.physicalDevice.physicalDevice)),
        .fDevice = @as(*skia.vk_device_t, @ptrCast(vulkan.device.device)),
        .fGraphicsQueueIndex = vulkan.queueFamily.graphicsFamily.?,
        .fQueue = @as(*skia.vk_queue_t, @ptrCast(vulkan.queue.graphicsQueue)),
        .fVkExtensions = extensions,
        .fGetProc = getProc,
        .fMinAPIVersion = c.VK_MAKE_VERSION(1, 1, 0),
    };

    std.debug.print("Init context\n", .{});

    context = skia.gr_direct_context_make_vulkan(vkContext) orelse return error.SkiaCreateContextFailed;

    const size = window.getSize();

    try window.clear();

    var imageInfo = skia.gr_vk_imageinfo_t{
        .fImage = vulkan.imageIndex,
        // .fImageLayout =
        .fImageUsageFlags = vulkan.swapChain.capabilities.supportedUsageFlags,
        .fSampleCount = c.VK_SAMPLE_COUNT_1_BIT,
        .fLevelCount = 1,
        .fFormat = vulkan.swapChain.format.format,
        .fCurrentQueueFamily = vulkan.queueFamily.graphicsFamily.?,
        .fSharingMode = vulkan.swapChain.imageSharingMode,
    };

    std.debug.print("Init backend\n", .{});

    backendRenderTarget = skia.gr_backendrendertarget_new_vulkan(@intCast(size.x), @intCast(size.y), @ptrCast(&imageInfo)) orelse return error.SkiaCreateRenderTargetFailed;

    std.debug.print("Init Skia\n", .{});

    const color_type = skia.BGRA_8888_SK_COLORTYPE;
    surface = skia.sk_surface_new_backend_render_target(@ptrCast(context), backendRenderTarget, skia.BOTTOM_LEFT_GR_SURFACE_ORIGIN, color_type, null, null) orelse return error.SkiaCreateSurfaceFailed;

    try window.draw();

    // canvas = skia.sk_surface_get_canvas(surface) orelse unreachable;
    // skia.sk_canvas_clear(canvas, 0xffffffff);
}

pub fn deinit() void {
    std.debug.print("Deinit skia\n", .{});
    _ = c.vkDeviceWaitIdle(vulkan.device.device);

    // skia.sk_canvas_destroy(canvas);

    skia.sk_surface_unref(surface);

    skia.gr_backendrendertarget_delete(backendRenderTarget);
    skia.gr_direct_context_free_gpu_resources(context);
    skia.gr_vk_extensions_delete(extensions);
}

pub fn draw() void {
    skia.gr_direct_context_flush(context);
    skia.sk_canvas_clear(canvas, 0xffffffff);
}

pub fn getNative() ?*skia.sk_canvas_t {
    return canvas;
}
