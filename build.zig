const std = @import("std");
const protobuf = @import("protobuf");

const shader_files: []const []const u8 = &.{
    "./shaders/fragment",
    "./shaders/vertex",
};

pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("Leaks deteced!");
    }

    const alloc = gpa.allocator();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "UniNote",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // protobuf
    const protobuf_dep = b.dependency("protobuf", .{
        .target = target,
        .optimize = optimize,
    });

    const gen_proto = b.step("gen-proto", "generates zig files from protocol buffer definitions");

    const protoc_step = protobuf.RunProtocStep.create(b, protobuf_dep.builder, target, .{
        .destination_directory = b.path("src/proto"),
        .source_files = &.{
            "proto/test.proto",
        },
        .include_directories = &.{},
    });

    gen_proto.dependOn(&protoc_step.step);

    exe.root_module.addImport("protobuf", protobuf_dep.module("protobuf"));

    // cimgui & imgui
    const cimgui_dep = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(cimgui_dep.path(""));
    exe.addIncludePath(cimgui_dep.path("imgui"));
    exe.addIncludePath(b.path("deps/interfaces/"));

    exe.addCSourceFiles(.{
        .root = cimgui_dep.path(""),
        .flags = &.{"-DIMGUI_IMPL_API=extern \"C\""},
        .files = &.{
            "cimgui.cpp",
            "imgui/imgui.cpp",
            "imgui/imgui_widgets.cpp",
            "imgui/imgui_draw.cpp",
            "imgui/imgui_tables.cpp",
            "imgui/imgui_demo.cpp",
            "imgui/backends/imgui_impl_sdl3.cpp",
            "imgui/backends/imgui_impl_vulkan.cpp",
        },
    });

    // SDL3
    exe.linkSystemLibrary("SDL3");

    // Vulkan
    exe.linkSystemLibrary("vulkan");

    // VMA
    const vma_dep = b.dependency("vma", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(vma_dep.path("include"));
    exe.addCSourceFiles(.{
        .root = b.path("deps/interfaces/"),
        .files = &.{"vk_mem_alloc.cpp"},
    });

    // libc
    exe.linkLibC();
    exe.linkLibCpp();

    b.installArtifact(exe);

    var gen_shader = try alloc.alloc(*std.Build.Step.Run, shader_files.len);
    defer alloc.free(gen_shader);

    for (shader_files, 0..) |file, i| {
        gen_shader[i] = b.addSystemCommand(&.{"naga"});
        gen_shader[i].addArgs(&.{
            b.fmt("{s}.wgsl", .{file}),
            b.fmt("{s}.spv", .{file}),
            "--keep-coordinate-space",
        });
    }

    const gen_step = b.step("gen", "Generates shaders and protobuf");

    gen_step.dependOn(gen_proto);
    for (gen_shader) |shader| {
        gen_step.dependOn(&shader.step);
    }

    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(gen_step);
    run_step.dependOn(&run_cmd.step);

    const run_only_step = b.step("run-only", "Only run the app");
    run_only_step.dependOn(&run_cmd.step);

    const resources = b.addInstallDirectory(.{
        .include_extensions = &.{".ttf"},
        .source_dir = b.path("res"),
        .install_dir = .prefix,
        .install_subdir = "bin/res",
    });
    b.getInstallStep().dependOn(&resources.step);

    const shaders = b.addInstallDirectory(.{
        .include_extensions = &.{".spv"},
        .source_dir = b.path("shaders"),
        .install_dir = .prefix,
        .install_subdir = "bin/shaders",
    });
    for (gen_shader) |shader| {
        shaders.step.dependOn(&shader.step);
    }
    b.getInstallStep().dependOn(&shaders.step);
}
