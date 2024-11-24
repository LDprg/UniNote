const std = @import("std");

const c = @import("../c.zig");

const util = @import("util.zig");
const device = @import("device.zig");

pub var alloc: std.mem.Allocator = undefined;

pub fn init(alloc_root: std.mem.Allocator) !void {
    alloc = alloc_root;

    const vertShaderCode = try loadShader("shaders/test.vert.spv");
    const fragShaderCode = try loadShader("shaders/test.frag.spv");

    const vertShaderModule = try createShaderModule(vertShaderCode);
    const fragShaderModule = try createShaderModule(fragShaderCode);

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
