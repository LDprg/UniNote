const std = @import("std");
const protobuf = @import("protobuf");

pub fn build(b: *std.Build) void {
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
    exe.addIncludePath(cimgui_dep.path("generator/output"));
    exe.addIncludePath(cimgui_dep.path("imgui"));
    exe.addIncludePath(cimgui_dep.path("imgui/backends"));
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

    // libc
    exe.linkLibC();
    exe.linkLibCpp();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");

    run_step.dependOn(gen_proto);
    run_step.dependOn(&run_cmd.step);

    const resources = b.addInstallDirectory(.{
        .include_extensions = &.{".ttf"},
        .source_dir = b.path("res"),
        .install_dir = .prefix,
        .install_subdir = "bin/res",
    });

    b.getInstallStep().dependOn(&resources.step);
}
