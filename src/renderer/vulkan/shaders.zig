const std = @import("std");

const c = @import("root").c;

const device = @import("root").renderer.vulkan.device;
const util = @import("root").renderer.vulkan.util;

pub var shader_stages: []c.VkPipelineShaderStageCreateInfo = undefined;

var vert_shader_module: c.VkShaderModule = undefined;
var frag_shader_module: c.VkShaderModule = undefined;

var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    const vert_shader_code = try loadShader("shaders/vertex.spv");
    const frag_shader_code = try loadShader("shaders/fragment.spv");

    vert_shader_module = try createShaderModule(vert_shader_code);
    frag_shader_module = try createShaderModule(frag_shader_code);

    const vert_shader_stage_info = c.VkPipelineShaderStageCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
        .module = vert_shader_module,
        .pName = "main",
    };

    const frag_shader_stage_info = c.VkPipelineShaderStageCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = frag_shader_module,
        .pName = "main",
    };

    shader_stages = try alloc.alloc(c.VkPipelineShaderStageCreateInfo, 2);
    shader_stages[0] = vert_shader_stage_info;
    shader_stages[1] = frag_shader_stage_info;
}

pub fn deinit() void {
    c.vkDestroyShaderModule(device.device, frag_shader_module, null);
    c.vkDestroyShaderModule(device.device, vert_shader_module, null);
}

pub fn loadShader(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_stat = try file.stat();

    const buf = try alloc.alloc(u8, file_stat.size);

    _ = try file.readAll(buf);

    return buf;
}

pub fn createShaderModule(code: []const u8) !c.VkShaderModule {
    const create_info = c.VkShaderModuleCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @ptrCast(@alignCast(code.ptr)),
    };

    var shader_module: c.VkShaderModule = null;
    try util.check_vk(c.vkCreateShaderModule(device.device, &create_info, null, &shader_module));

    return shader_module;
}
