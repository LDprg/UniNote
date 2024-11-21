const std = @import("std");

const skia = @import("skia-zig");

const c = @import("c.zig");

const window = @import("window.zig");

const validationLayers = &[_][*]const u8{"VK_LAYER_KHRONOS_validation"};
const deviceExtensions = &[_][*]const u8{"VK_KHR_swapchain"};

var vkInstance: c.VkInstance = undefined;
var vkSurface: c.VkSurfaceKHR = undefined;
var vkPhysicalDevices: []c.VkPhysicalDevice = undefined;
var vkPhysicalDevice: c.VkPhysicalDevice = undefined;
var vkQueueFamilyProperties: []c.VkQueueFamilyProperties = undefined;
var vkDevice: c.VkDevice = undefined;

var vkContext: skia.gr_vk_backendcontext_t = undefined;
var context: ?*skia.gr_direct_context_t = undefined;
var backendRenderTarget: ?*skia.gr_backendrendertarget_t = undefined;
var surface: ?*skia.sk_surface_t = undefined;
var canvas: ?*skia.sk_canvas_t = undefined;

pub fn init(
    alloc: std.mem.Allocator,
) !void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Instance
    var extensionCount: u32 = 0;

    const extensionNames = c.SDL_Vulkan_GetInstanceExtensions(&extensionCount);

    var appInfo = std.mem.zeroInit(c.VkApplicationInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .apiVersion = c.VK_API_VERSION_1_0,
        .pApplicationName = window.getWindowTitle(),
        .pEngineName = "No Engine",
    });

    var instanceCreateInfo = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &appInfo,
        // .enabledLayerCount = 0,
        .enabledLayerCount = validationLayers.len,
        .ppEnabledLayerNames = validationLayers,
        .enabledExtensionCount = extensionCount,
        .ppEnabledExtensionNames = extensionNames,
    });

    try check_vk(c.vkCreateInstance(&instanceCreateInfo, null, &vkInstance));

    // Surface
    _ = c.SDL_Vulkan_CreateSurface(window.getNativeWindow(), vkInstance, null, &vkSurface);

    // Physical Device
    std.debug.print("Physical Device\n", .{});

    var physicalDeviceCount: u32 = 0;
    try check_vk(c.vkEnumeratePhysicalDevices(vkInstance, &physicalDeviceCount, null));

    vkPhysicalDevices = try arena.alloc(c.VkPhysicalDevice, physicalDeviceCount);

    try check_vk(c.vkEnumeratePhysicalDevices(vkInstance, &physicalDeviceCount, vkPhysicalDevices.ptr));

    vkPhysicalDevice = vkPhysicalDevices[0];

    // Queue Family
    std.debug.print("Queue Family\n", .{});

    var graphics_QueueFamilyIndex: ?u32 = null;
    var present_QueueFamilyIndex: ?u32 = null;

    var queueFamilyCount: u32 = 0;
    c.vkGetPhysicalDeviceQueueFamilyProperties(vkPhysicalDevice, &queueFamilyCount, null);

    vkQueueFamilyProperties = try alloc.alloc(c.VkQueueFamilyProperties, queueFamilyCount);

    c.vkGetPhysicalDeviceQueueFamilyProperties(vkPhysicalDevice, &queueFamilyCount, vkQueueFamilyProperties.ptr);

    for (vkQueueFamilyProperties, 0..) |queueFamily, i| {
        if (queueFamily.queueCount > 0 and (queueFamily.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0)
            graphics_QueueFamilyIndex = @intCast(i);

        var presentSupport: u32 = 0;
        try check_vk(c.vkGetPhysicalDeviceSurfaceSupportKHR(vkPhysicalDevice, @intCast(i), vkSurface, &presentSupport));
        if (queueFamily.queueCount > 0 and presentSupport != 0) {
            present_QueueFamilyIndex = @intCast(i);
        }

        if (graphics_QueueFamilyIndex != null and present_QueueFamilyIndex != null)
            break;
    }

    // Device
    std.debug.print("Device\n", .{});

    var queueCreateInfos = std.ArrayListUnmanaged(c.VkDeviceQueueCreateInfo){};
    const queuePriority: f32 = 1.0;

    try queueCreateInfos.append(alloc, std.mem.zeroInit(c.VkDeviceQueueCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = graphics_QueueFamilyIndex.?,
        .queueCount = 1,
        .pQueuePriorities = &queuePriority,
    }));

    // try queueCreateInfos.append(alloc, std.mem.zeroInit(c.VkDeviceQueueCreateInfo, .{
    //     .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
    //     .queueFamilyIndex = present_QueueFamilyIndex.?,
    //     .queueCount = 1,
    //     .pQueuePriorities = &queuePriority,
    // }));

    var deviceFeatures = std.mem.zeroInit(c.VkPhysicalDeviceFeatures, .{
        .samplerAnisotropy = c.VK_TRUE,
    });

    var createInfo = std.mem.zeroInit(c.VkDeviceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext = null,
        .queueCreateInfoCount = @as(u32, @intCast(queueCreateInfos.items.len)),
        .pQueueCreateInfos = queueCreateInfos.items.ptr,
        .enabledLayerCount = validationLayers.len,
        .ppEnabledLayerNames = validationLayers,
        .enabledExtensionCount = deviceExtensions.len,
        .ppEnabledExtensionNames = deviceExtensions,
        .pEnabledFeatures = &deviceFeatures,
    });

    try check_vk(c.vkCreateDevice(vkPhysicalDevice, &createInfo, null, &vkDevice));

    std.debug.print("Skia", .{});c.SDL_Vulkan_GetVkGetInstanceProcAddr()

    // Context
    vkContext = std.mem.zeroInit(skia.gr_vk_backendcontext_t, .{
        .fInstance = @as(*skia.vk_instance_t, @ptrCast(vkInstance)),
        .fPhysicalDevice = @as(*skia.vk_physical_device_t, @ptrCast(vkPhysicalDevice)),
        .fGraphicsQueueIndex = graphics_QueueFamilyIndex.?,
        .fDevice = @as(*skia.vk_device_t, @ptrCast(vkDevice)),

    });

    context = skia.gr_direct_context_make_vulkan(vkContext);
    // skia.gr_direct_context_free_gpu_resources(context);

    const size = window.getSize();

    var imageInfo: skia.gr_vk_imageinfo_t = .{ .fSampleCount = 1, .fLevelCount = 1, .fFormat = c.VK_FORMAT_R32G32B32A32_SFLOAT, .fCurrentQueueFamily = graphics_QueueFamilyIndex.? };

    backendRenderTarget = skia.gr_backendrendertarget_new_vulkan(size.x, size.y, &imageInfo);
    surface = skia.sk_surface_new_backend_render_target(@ptrCast(context), backendRenderTarget, skia.BOTTOM_LEFT_GR_SURFACE_ORIGIN, skia.RGBA_F32_SK_COLORTYPE, null, null);

    canvas = skia.sk_surface_get_canvas(surface);
}

pub fn deinit() void {
    skia.sk_canvas_destroy(canvas);
    skia.sk_surface_unref(surface);
    c.SDL_Vulkan_DestroySurface(vkInstance, vkSurface, null);
    c.vkDestroyInstance(vkInstance, null);
}

pub fn draw() void {
    skia.sk_canvas_clear(canvas, 0xffffffff);

    const fill = skia.sk_paint_new();
    defer skia.sk_paint_delete(fill);
    skia.sk_paint_set_color(fill, 0xff0000ff);
    skia.sk_canvas_draw_paint(canvas, fill);

    skia.gr_direct_context_flush_and_submit(context, true);
}

pub fn check_vk(result: c.VkResult) !void {
    return switch (result) {
        c.VK_SUCCESS => {},
        c.VK_NOT_READY => error.vk_not_ready,
        c.VK_TIMEOUT => error.vk_timeout,
        c.VK_EVENT_SET => error.vk_event_set,
        c.VK_EVENT_RESET => error.vk_event_reset,
        c.VK_INCOMPLETE => error.vk_incomplete,
        c.VK_ERROR_OUT_OF_HOST_MEMORY => error.vk_error_out_of_host_memory,
        c.VK_ERROR_OUT_OF_DEVICE_MEMORY => error.vk_error_out_of_device_memory,
        c.VK_ERROR_INITIALIZATION_FAILED => error.vk_error_initialization_failed,
        c.VK_ERROR_DEVICE_LOST => error.vk_error_device_lost,
        c.VK_ERROR_MEMORY_MAP_FAILED => error.vk_error_memory_map_failed,
        c.VK_ERROR_LAYER_NOT_PRESENT => error.vk_error_layer_not_present,
        c.VK_ERROR_EXTENSION_NOT_PRESENT => error.vk_error_extension_not_present,
        c.VK_ERROR_FEATURE_NOT_PRESENT => error.vk_error_feature_not_present,
        c.VK_ERROR_INCOMPATIBLE_DRIVER => error.vk_error_incompatible_driver,
        c.VK_ERROR_TOO_MANY_OBJECTS => error.vk_error_too_many_objects,
        c.VK_ERROR_FORMAT_NOT_SUPPORTED => error.vk_error_format_not_supported,
        c.VK_ERROR_FRAGMENTED_POOL => error.vk_error_fragmented_pool,
        c.VK_ERROR_UNKNOWN => error.vk_error_unknown,
        c.VK_ERROR_OUT_OF_POOL_MEMORY => error.vk_error_out_of_pool_memory,
        c.VK_ERROR_INVALID_EXTERNAL_HANDLE => error.vk_error_invalid_external_handle,
        c.VK_ERROR_FRAGMENTATION => error.vk_error_fragmentation,
        c.VK_ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.vk_error_invalid_opaque_capture_address,
        c.VK_PIPELINE_COMPILE_REQUIRED => error.vk_pipeline_compile_required,
        c.VK_ERROR_SURFACE_LOST_KHR => error.vk_error_surface_lost_khr,
        c.VK_ERROR_NATIVE_WINDOW_IN_USE_KHR => error.vk_error_native_window_in_use_khr,
        c.VK_SUBOPTIMAL_KHR => error.vk_suboptimal_khr,
        c.VK_ERROR_OUT_OF_DATE_KHR => error.vk_error_out_of_date_khr,
        c.VK_ERROR_INCOMPATIBLE_DISPLAY_KHR => error.vk_error_incompatible_display_khr,
        c.VK_ERROR_VALIDATION_FAILED_EXT => error.vk_error_validation_failed_ext,
        c.VK_ERROR_INVALID_SHADER_NV => error.vk_error_invalid_shader_nv,
        c.VK_ERROR_IMAGE_USAGE_NOT_SUPPORTED_KHR => error.vk_error_image_usage_not_supported_khr,
        c.VK_ERROR_VIDEO_PICTURE_LAYOUT_NOT_SUPPORTED_KHR => error.vk_error_video_picture_layout_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_OPERATION_NOT_SUPPORTED_KHR => error.vk_error_video_profile_operation_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_FORMAT_NOT_SUPPORTED_KHR => error.vk_error_video_profile_format_not_supported_khr,
        c.VK_ERROR_VIDEO_PROFILE_CODEC_NOT_SUPPORTED_KHR => error.vk_error_video_profile_codec_not_supported_khr,
        c.VK_ERROR_VIDEO_STD_VERSION_NOT_SUPPORTED_KHR => error.vk_error_video_std_version_not_supported_khr,
        c.VK_ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT => error.vk_error_invalid_drm_format_modifier_plane_layout_ext,
        c.VK_ERROR_NOT_PERMITTED_KHR => error.vk_error_not_permitted_khr,
        c.VK_ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => error.vk_error_full_screen_exclusive_mode_lost_ext,
        c.VK_THREAD_IDLE_KHR => error.vk_thread_idle_khr,
        c.VK_THREAD_DONE_KHR => error.vk_thread_done_khr,
        c.VK_OPERATION_DEFERRED_KHR => error.vk_operation_deferred_khr,
        c.VK_OPERATION_NOT_DEFERRED_KHR => error.vk_operation_not_deferred_khr,
        c.VK_ERROR_COMPRESSION_EXHAUSTED_EXT => error.vk_error_compression_exhausted_ext,
        c.VK_ERROR_INCOMPATIBLE_SHADER_BINARY_EXT => error.vk_error_incompatible_shader_binary_ext,
        else => error.vk_errror_unknown,
    };
}
