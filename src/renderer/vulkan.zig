const std = @import("std");

const zmath = @import("zmath");

const c = @import("root").c;

const imgui = @import("root").renderer.imgui;

pub const allocator = @import("vulkan/allocator.zig");
pub const command_buffer = @import("vulkan/command_buffer.zig");
pub const descriptor_pool = @import("vulkan/descriptor_pool.zig");
pub const descriptor_set_layout = @import("vulkan/descriptor_set_layout.zig");
pub const descriptor_sets = @import("vulkan/descriptor_sets.zig");
pub const device = @import("vulkan/device.zig");
pub const frame_buffer = @import("vulkan/frame_buffer.zig");
pub const image_view = @import("vulkan/image_view.zig");
pub const instance = @import("vulkan/instance.zig");
pub const physical_device = @import("vulkan/physical_device.zig");
pub const pipeline = @import("vulkan/pipeline.zig");
pub const queue = @import("vulkan/queue.zig");
pub const queue_family = @import("vulkan/queue_family.zig");
pub const render_pass = @import("vulkan/render_pass.zig");
pub const shaders = @import("vulkan/shaders.zig");
pub const surface = @import("vulkan/surface.zig");
pub const swapchain = @import("vulkan/swapchain.zig");
pub const sync_objects = @import("vulkan/sync_objects.zig");
pub const uniform_buffers = @import("vulkan/uniform_buffers.zig");
pub const util = @import("vulkan/util.zig");
pub const vertex_buffer = @import("vulkan/vertex_buffer.zig");

pub var image_index: u32 = undefined;
pub var current_frame: u32 = 0;

pub var swapchain_rebuild = false;

var alloc_arena: std.heap.ArenaAllocator = undefined;
var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    std.log.info("Init Vulkan", .{});

    alloc_arena = std.heap.ArenaAllocator.init(alloc_root);
    alloc = alloc_arena.allocator();

    try instance.init();
    try surface.init();
    try physical_device.init(alloc);
    try queue_family.init(alloc);
    try device.init(alloc);
    try allocator.init();
    try queue.init();
    try swapchain.init(alloc);
    try image_view.init(alloc);
    try render_pass.init();
    try shaders.init(alloc);
    try descriptor_set_layout.init();
    try pipeline.init(alloc);
    try frame_buffer.init(alloc);
    try command_buffer.init();
    try sync_objects.init();
    try uniform_buffers.init(alloc);
    try descriptor_pool.init();
    try descriptor_sets.init(alloc);
}

pub fn deinit() void {
    std.log.info("Deinit Vulkan", .{});
    _ = c.vkDeviceWaitIdle(device.device);

    descriptor_pool.deinit();
    uniform_buffers.deinit();
    sync_objects.deinit();
    command_buffer.deinit();
    frame_buffer.deinit();
    pipeline.deinit();
    descriptor_set_layout.deinit();
    shaders.deinit();
    render_pass.deinit();
    image_view.deinit();
    swapchain.deinit();
    allocator.deinit();
    device.deinit();
    surface.deinit();
    instance.deinit();

    alloc_arena.deinit();
}

pub fn rebuildSwapChain() !void {
    std.log.debug("Rebuild Swapchain", .{});
    try util.check_vk(c.vkDeviceWaitIdle(device.device));

    frame_buffer.deinit();
    image_view.deinit();
    swapchain.deinit();

    try swapchain.init(alloc);
    try image_view.init(alloc);
    try frame_buffer.init(alloc);

    swapchain_rebuild = false;
}

pub fn clear() !void {
    try util.check_vk(c.vkWaitForFences(device.device, 1, &sync_objects.in_flight_fences[current_frame], c.VK_TRUE, c.UINT64_MAX));

    const res = c.vkAcquireNextImageKHR(
        device.device,
        swapchain.swapchain,
        c.UINT64_MAX,
        sync_objects.image_available_semaphores[current_frame],
        null,
        &image_index,
    );

    if (res == c.VK_ERROR_OUT_OF_DATE_KHR) {
        swapchain_rebuild = true;
        return;
    } else if (res != c.VK_SUBOPTIMAL_KHR) {
        try util.check_vk(res);
    }

    try util.check_vk(c.vkResetFences(device.device, 1, &sync_objects.in_flight_fences[current_frame]));
    try util.check_vk(c.vkResetCommandBuffer(command_buffer.command_buffers[current_frame], 0));

    try command_buffer.beginCommandBuffer(command_buffer.command_buffers[current_frame], image_index);

    c.vkCmdBindPipeline(
        command_buffer.command_buffers[current_frame],
        c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        pipeline.graphics_pipeline,
    );
}

pub fn draw() !void {
    const w = 2 / @as(f32, @floatFromInt(swapchain.extent.width));
    const h = 2 / @as(f32, @floatFromInt(swapchain.extent.height));

    const view = zmath.mul(zmath.mul(zmath.identity(), zmath.scaling(w, h, 1)), zmath.translation(-1, -1, 0));

    var ubo = [_]uniform_buffers.UniformBufferObject{uniform_buffers.UniformBufferObject{
        .view = view,
    }};

    @memcpy(
        @as([*]uniform_buffers.UniformBufferObject, @ptrCast(@alignCast(uniform_buffers.uniform_buffers[current_frame].buffer_alloc_info.?.pMappedData))),
        &ubo,
    );

    try command_buffer.endCommandBuffer(command_buffer.command_buffers[current_frame]);

    const wait_semaphores: []const c.VkSemaphore = &.{sync_objects.image_available_semaphores[current_frame]};
    const wait_stages: []const c.VkPipelineStageFlags = &.{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
    const signal_semaphores: []const c.VkSemaphore = &.{sync_objects.render_finished_semaphores[current_frame]};

    var submit_info = c.VkSubmitInfo{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .waitSemaphoreCount = @intCast(wait_semaphores.len),
        .pWaitSemaphores = wait_semaphores.ptr,
        .pWaitDstStageMask = wait_stages.ptr,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer.command_buffers[current_frame],
        .signalSemaphoreCount = @intCast(signal_semaphores.len),
        .pSignalSemaphores = signal_semaphores.ptr,
    };

    try util.check_vk(c.vkQueueSubmit(queue.graphics_queue, 1, &submit_info, sync_objects.in_flight_fences[current_frame]));

    // Present
    const swapchains: []const c.VkSwapchainKHR = &.{swapchain.swapchain};

    const present_info = c.VkPresentInfoKHR{
        .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        .waitSemaphoreCount = @intCast(signal_semaphores.len),
        .pWaitSemaphores = signal_semaphores.ptr,
        .swapchainCount = @intCast(swapchains.len),
        .pSwapchains = swapchains.ptr,
        .pImageIndices = &image_index,
        .pResults = null,
    };

    const res = c.vkQueuePresentKHR(queue.present_queue, &present_info);
    if (res == c.VK_ERROR_OUT_OF_DATE_KHR or res == c.VK_SUBOPTIMAL_KHR) {
        swapchain_rebuild = true;
    } else {
        try util.check_vk(res);
    }

    current_frame = (current_frame + 1) % util.max_frames_in_fligth;
}
