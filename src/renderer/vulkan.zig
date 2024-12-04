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

var arena_state: std.heap.ArenaAllocator = undefined;
var arena: std.mem.Allocator = undefined;

pub fn init(alloc: std.mem.Allocator) !void {
    std.debug.print("Init Vulkan\n", .{});

    arena_state = std.heap.ArenaAllocator.init(alloc);
    arena = arena_state.allocator();

    try instance.init();
    try surface.init();
    try physical_device.init(arena);
    try queue_family.init(arena);
    try device.init(arena);
    try allocator.init();
    try queue.init();
    try swapchain.init(arena);
    try image_view.init(arena);
    try render_pass.init();
    try shaders.init(arena);
    try descriptor_set_layout.init();
    try pipeline.init(arena);
    try frame_buffer.init(arena);
    try command_buffer.init();
    try sync_objects.init();
    try uniform_buffers.init(arena);
    try descriptor_pool.init();
    try descriptor_sets.init(arena);

    var vertex = [_]vertex_buffer.Vertex{
        vertex_buffer.Vertex{ .pos = [2]f32{ 100, 100 }, .color = [4]f32{ 1, 0, 0, 1 } },
        vertex_buffer.Vertex{ .pos = [2]f32{ 500, 100 }, .color = [4]f32{ 0, 1, 0, 1 } },
        vertex_buffer.Vertex{ .pos = [2]f32{ 500, 500 }, .color = [4]f32{ 0, 0, 1, 1 } },
        vertex_buffer.Vertex{ .pos = [2]f32{ 100, 500 }, .color = [4]f32{ 1, 0, 1, 1 } },
    };
    var index = [_]u16{ 0, 1, 2, 2, 3, 0 };
    try vertex_buffer.init(&vertex, &index);
}

pub fn deinit() void {
    std.debug.print("Deinit Vulkan\n", .{});
    _ = c.vkDeviceWaitIdle(device.device);

    vertex_buffer.deinit();

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

    arena_state.deinit();
}

pub fn rebuildSwapChain() !void {
    try util.check_vk(c.vkDeviceWaitIdle(device.device));

    frame_buffer.deinit();
    image_view.deinit();
    swapchain.deinit();

    try swapchain.init(arena);
    try image_view.init(arena);
    try frame_buffer.init(arena);

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

    const vertex_buffers: [*]const c.VkBuffer = &.{vertex_buffer.vertex_buffer.buffer};
    const offsets: [*]const c.VkDeviceSize = &.{0};
    c.vkCmdBindVertexBuffers(
        command_buffer.command_buffers[current_frame],
        0,
        1,
        vertex_buffers,
        offsets,
    );
    c.vkCmdBindIndexBuffer(
        command_buffer.command_buffers[current_frame],
        vertex_buffer.index_buffer.buffer,
        0,
        c.VK_INDEX_TYPE_UINT16,
    );

    const viewport = c.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(swapchain.extent.width),
        .height = @floatFromInt(swapchain.extent.height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };
    c.vkCmdSetViewport(
        command_buffer.command_buffers[current_frame],
        0,
        1,
        &viewport,
    );

    const scissor = c.VkRect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = swapchain.extent,
    };
    c.vkCmdSetScissor(
        command_buffer.command_buffers[current_frame],
        0,
        1,
        &scissor,
    );

    c.vkCmdBindDescriptorSets(
        command_buffer.command_buffers[current_frame],
        c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        pipeline.pipeline_layout,
        0,
        1,
        &descriptor_sets.descriptor_sets[current_frame],
        0,
        null,
    );

    c.vkCmdDrawIndexed(command_buffer.command_buffers[current_frame], 6, 1, 0, 0, 0);
}

pub fn draw() !void {
    const w = 2 / @as(f32, @floatFromInt(swapchain.extent.width));
    const h = 2 / @as(f32, @floatFromInt(swapchain.extent.height));

    const view = zmath.mul(zmath.mul(zmath.identity(), zmath.scaling(w, h, 1)), zmath.translation(-1, -1, 0));

    var ubo = [_]uniform_buffers.UniformBufferObject{uniform_buffers.UniformBufferObject{
        .model = zmath.identity(),
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
