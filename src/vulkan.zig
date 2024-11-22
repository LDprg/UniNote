const std = @import("std");

const c = @import("c.zig");

const window = @import("window.zig");

pub var g_Allocator: ?*c.VkAllocationCallbacks = null;
pub var g_Instance: c.VkInstance = undefined;
pub var g_PhysicalDevice: c.VkPhysicalDevice = undefined;
pub var g_Device: c.VkDevice = undefined;
pub var g_QueueFamily: ?u32 = null;
pub var g_Queue: c.VkQueue = undefined;
pub var g_PipelineCache: c.VkPipelineCache = null;
pub var g_DescriptorPool: c.VkDescriptorPool = undefined;

pub var g_CommandPool: c.VkCommandPool = undefined;
pub var g_CommandBuffer: c.VkCommandBuffer = undefined;

pub var g_SwapChainRebuild = false;

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Enabling validation layers
    // const layers: []const [*]const u8 = &.{"VK_LAYER_KHRONOS_validation"};
    const layers: []const [*]const u8 = &.{};

    // Vk Instance
    const inst_create_info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .enabledExtensionCount = @as(u32, @intCast(window.extensions.len)),
        .ppEnabledExtensionNames = window.extensions.ptr,
        .enabledLayerCount = @as(u32, @intCast(layers.len)),
        .ppEnabledLayerNames = layers.ptr,
    });

    try check_vk(c.vkCreateInstance(&inst_create_info, g_Allocator, &g_Instance));

    // Get gpus
    var gpu_count: u32 = undefined;
    try check_vk(c.vkEnumeratePhysicalDevices(g_Instance, &gpu_count, null));
    try std.testing.expect(gpu_count > 0);

    const gpus = try arena.alloc(c.VkPhysicalDevice, gpu_count);
    defer arena.free(gpus);

    try check_vk(c.vkEnumeratePhysicalDevices(g_Instance, &gpu_count, gpus.ptr));

    // Select gpu
    var use_gpu: usize = 0;
    for (gpus, 0..) |gpu, i| {
        var properties: c.VkPhysicalDeviceProperties = undefined;
        c.vkGetPhysicalDeviceProperties(gpu, &properties);
        if (properties.deviceType == c.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            use_gpu = i;
            break;
        }
    }

    g_PhysicalDevice = gpus[use_gpu];

    // Select graphics queue family
    var count: u32 = undefined;
    c.vkGetPhysicalDeviceQueueFamilyProperties(g_PhysicalDevice, &count, null);

    const queues = try arena.alloc(c.VkQueueFamilyProperties, count);
    defer arena.free(queues);

    c.vkGetPhysicalDeviceQueueFamilyProperties(g_PhysicalDevice, &count, queues.ptr);

    for (queues, 0..) |queue, i| {
        if (queue.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            g_QueueFamily = @intCast(i);
            break;
        }
    }
    try std.testing.expect(g_QueueFamily != null);

    // Create Logical Device (with 1 queue)
    const device_extension_count = 1;
    const device_extensions: []const [*]const u8 = &.{"VK_KHR_swapchain"};
    const queue_priority: []const f32 = &.{1.0};

    const queue_info: []const c.VkDeviceQueueCreateInfo = &.{.{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = g_QueueFamily.?,
        .queueCount = 1,
        .pQueuePriorities = queue_priority.ptr,
    }};

    const create_info = std.mem.zeroInit(c.VkDeviceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = @as(u32, @intCast(queue_info.len)),
        .pQueueCreateInfos = queue_info.ptr,
        .enabledExtensionCount = device_extension_count,
        .ppEnabledExtensionNames = device_extensions.ptr,
    });

    try check_vk(c.vkCreateDevice(g_PhysicalDevice, &create_info, g_Allocator, &g_Device));
    c.vkGetDeviceQueue(g_Device, g_QueueFamily.?, 0, &g_Queue);

    // Create Descriptor Pool
    const pool_sizes: []const c.VkDescriptorPoolSize = &.{
        .{ .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, .descriptorCount = 1000 },
        .{ .type = c.VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, .descriptorCount = 1000 },
    };
    const pool_info = std.mem.zeroInit(c.VkDescriptorPoolCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .flags = c.VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT,
        .maxSets = 1000 * pool_sizes.len,
        .poolSizeCount = pool_sizes.len,
        .pPoolSizes = pool_sizes.ptr,
    });

    try check_vk(c.vkCreateDescriptorPool(g_Device, &pool_info, g_Allocator, &g_DescriptorPool));
}

pub fn deinit() void {
    c.vkDestroyDescriptorPool(g_Device, g_DescriptorPool, g_Allocator);

    c.vkDestroyDevice(g_Device, g_Allocator);
    c.vkDestroyInstance(g_Instance, g_Allocator);
}

pub fn check_vk_c(result: c.VkResult) callconv(.C) void {
    check_vk(result) catch |err| {
        std.debug.panic("VK ERROR: {}", .{err});
    };
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
