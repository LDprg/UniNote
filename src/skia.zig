const std = @import("std");

const vulkan = @import("vulkan.zig");

const skia = @import("skia-zig");
pub usingnamespace skia;

const c = @import("c.zig");

const window = @import("window.zig");

var vkContext: skia.gr_vk_backendcontext_t = undefined;
var context: ?*skia.gr_direct_context_t = undefined;
var backendRenderTarget: ?*skia.gr_backendrendertarget_t = undefined;

var surface: ?*skia.sk_surface_t = undefined;
var canvas: ?*skia.sk_canvas_t = undefined;

pub fn init() !void {
    std.debug.print("Init Skia vulkan\n", .{});

    var physDeviceProperties: c.VkPhysicalDeviceProperties = undefined;
    c.vkGetPhysicalDeviceProperties(vulkan.g_PhysicalDevice, &physDeviceProperties);

    const getProc = struct {
        fn f(_: ?*anyopaque, proc_name: [*c]const u8, instance: ?*skia.vk_instance_t, device: ?*skia.vk_device_t) callconv(.C) skia.gr_vk_func_ptr {
            if (device != null) {
                return c.vkGetDeviceProcAddr(@as(c.VkDevice, @ptrCast(device)), proc_name);
            }
            return c.vkGetInstanceProcAddr(@as(c.VkInstance, @ptrCast(instance)), proc_name);
        }
    }.f;

    var features = c.VkPhysicalDeviceFeatures2{
        .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
        .pNext = null,
    };
    c.vkGetPhysicalDeviceFeatures2(vulkan.g_PhysicalDevice, &features);

    std.debug.print("Init extension\n", .{});

    const extensions = skia.gr_vk_extensions_new();
    skia.gr_vk_extensions_init(
        extensions,
        getProc,
        null,
        @as(*skia.vk_instance_t, @ptrCast(vulkan.g_Instance)),
        @as(*skia.vk_physical_device_t, @ptrCast(vulkan.g_PhysicalDevice)),
        @intCast(window.extensions.len),
        window.extensions.ptr,
        @intCast(vulkan.device_extensions.len),
        vulkan.device_extensions.ptr,
    );

    vkContext = std.mem.zeroInit(skia.gr_vk_backendcontext_t, .{
        .fInstance = @as(*skia.vk_instance_t, @ptrCast(vulkan.g_Instance)),
        .fPhysicalDevice = @as(*skia.vk_physical_device_t, @ptrCast(vulkan.g_PhysicalDevice)),
        .fDevice = @as(*skia.vk_device_t, @ptrCast(vulkan.g_Device)),
        .fQueue = @as(*skia.vk_queue_t, @ptrCast(vulkan.g_Queue)),
        .fGraphicsQueueIndex = vulkan.g_QueueFamily.?,
        .fMaxAPIVersion = physDeviceProperties.apiVersion,
        .fVkExtensions = extensions,
        .fDeviceFeatures2 = @as(*skia.vk_physical_device_features_2_t, @ptrCast(&features)),
        .fGetProc = getProc,
        .fOwnsInstanceAndDevice = false,
        .fProtectedContext = false,
    });

    std.debug.print("Init context\n", .{});

    context = skia.gr_direct_context_make_vulkan(vkContext) orelse return error.SkiaCreateContextFailed;

    const size = window.getSize();

    var imageInfo = std.mem.zeroInit(skia.gr_vk_imageinfo_t, .{
        // .fImage = window.surface,
        .fSampleCount = 1,
        .fLevelCount = 1,
        .fFormat = c.VK_FORMAT_R8G8B8A8_UNORM,
    });
    // var imageInfo = skia.sk_imageinfo_t{
    //     .height = size.x,
    //     .width = size.y,
    //     .colorType = skia.BGRA_8888_SK_COLORTYPE,
    //     .colorspace = null,
    //     .alphaType = skia.PREMUL_SK_ALPHATYPE,
    // };
    std.debug.print("Init backend\n", .{});

    backendRenderTarget = skia.gr_backendrendertarget_new_vulkan(size.x, size.y, @ptrCast(&imageInfo)) orelse return error.SkiaCreateRenderTargetFailed;

    std.debug.print("Init Skia\n", .{});

    const color_type = skia.BGRA_8888_SK_COLORTYPE;
    surface = skia.sk_surface_new_backend_render_target(@ptrCast(context), backendRenderTarget, skia.BOTTOM_LEFT_GR_SURFACE_ORIGIN, color_type, null, null) orelse return error.SkiaCreateSurfaceFailed;
    // surface = skia.sk_surface_new_render_target(@ptrCast(context), false, &imageInfo, 1, skia.BOTTOM_LEFT_GR_SURFACE_ORIGIN, null, false);

    canvas = skia.sk_surface_get_canvas(surface) orelse unreachable;
    skia.sk_canvas_clear(canvas, 0xffffffff);
}

pub fn deinit() void {
    skia.sk_surface_unref(surface);
    skia.gr_direct_context_free_gpu_resources(context);
}

pub fn draw() void {
    skia.gr_direct_context_flush(context);
    skia.sk_canvas_clear(canvas, 0xffffffff);
}

pub fn getNative() ?*skia.sk_canvas_t {
    return canvas;
}
