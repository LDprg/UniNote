const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");

pub var shaderStages: []c.VkPipelineShaderStageCreateInfo = undefined;
pub var alloc: std.mem.Allocator = undefined;

var vertShaderModule: c.VkShaderModule = undefined;
var fragShaderModule: c.VkShaderModule = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    const vertShaderCode = try loadShader("shaders/vertex.spv");
    const fragShaderCode = try loadShader("shaders/fragment.spv");

    vertShaderModule = try createShaderModule(vertShaderCode);
    fragShaderModule = try createShaderModule(fragShaderCode);

    const vertShaderStageInfo = c.VkPipelineShaderStageCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
        .module = vertShaderModule,
        .pName = "main",
    };

    const fragShaderStageInfo = c.VkPipelineShaderStageCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = fragShaderModule,
        .pName = "main",
    };

    shaderStages = try alloc.alloc(c.VkPipelineShaderStageCreateInfo, 2);
    shaderStages[0] = vertShaderStageInfo;
    shaderStages[1] = fragShaderStageInfo;
}

pub fn deinit() void {
    c.vkDestroyShaderModule(device.device, fragShaderModule, null);
    c.vkDestroyShaderModule(device.device, vertShaderModule, null);
}

pub fn loadShader(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const fileStat = try file.stat();

    const buf = try alloc.alloc(u8, fileStat.size);

    _ = try file.readAll(buf);

    return buf;
}

pub fn createShaderModule(code: []const u8) !c.VkShaderModule {
    const createInfo = c.VkShaderModuleCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .codeSize = code.len,
        .pCode = @ptrCast(@alignCast(code.ptr)),
    };

    var shaderModule: c.VkShaderModule = null;
    try util.check_vk(c.vkCreateShaderModule(device.device, &createInfo, null, &shaderModule));

    return shaderModule;
}
