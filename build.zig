const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "driven",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // zgpu
    {
        @import("zgpu").addLibraryPathsTo(exe);
        const zgpu = b.dependency("zgpu", .{ .target = target, .optimize = optimize });
        exe.root_module.addImport("zgpu", zgpu.module("root"));
        exe.linkLibrary(zgpu.artifact("zdawn"));
    }
    // zglfw
    {
        const zglfw = b.dependency("zglfw", .{ .target = target, .optimize = optimize });
        exe.root_module.addImport("zglfw", zglfw.module("root"));
        exe.linkLibrary(zglfw.artifact("glfw"));
    }
    // zmath
    {
        const zmath = b.dependency("zmath", .{
            .target = target,
            .optimize = optimize,
            .enable_cross_platform_determinism = false,
        });
        exe.root_module.addImport("zmath", zmath.module("root"));
    }

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // emscripten

    const activate_emsdk_step = @import("zemscripten").activateEmsdkStep(b);

    const wasm = b.addStaticLibrary(.{
        .name = "emscripten-output",
        .root_source_file = b.path("src/emscripten_entrypoint.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zemscripten = b.dependency("zemscripten", .{});
    wasm.root_module.addImport("zemscripten", zemscripten.module("root"));
    const emcc_flags = @import("zemscripten").emccDefaultFlags(b.allocator, optimize);
    var emcc_settings = @import("zemscripten").emccDefaultSettings(b.allocator, .{
        .optimize = optimize,
    });

    // zgpu
    {
        @import("zgpu").addLibraryPathsTo(wasm);
        const zgpu = b.dependency("zgpu", .{ .target = target, .optimize = optimize });
        wasm.root_module.addImport("zgpu", zgpu.module("root"));
        wasm.linkLibrary(zgpu.artifact("zdawn"));
    }
    // zglfw
    {
        const zglfw = b.dependency("zglfw", .{ .target = target, .optimize = optimize });
        wasm.root_module.addImport("zglfw", zglfw.module("root"));
        wasm.linkLibrary(zglfw.artifact("glfw"));
    }
    // zmath
    {
        const zmath = b.dependency("zmath", .{
            .target = target,
            .optimize = optimize,
            .enable_cross_platform_determinism = false,
        });
        wasm.root_module.addImport("zmath", zmath.module("root"));
    }

    try emcc_settings.put("ALLOW_MEMORY_GROWTH", "1");

    const emcc_step = @import("zemscripten").emccStep(
        b,
        wasm,
        .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .use_preload_plugins = true,
            .embed_paths = &.{},
            .preload_paths = &.{},
            .install_dir = .{ .custom = "web" },
        },
    );
    emcc_step.dependOn(activate_emsdk_step);

    b.getInstallStep().dependOn(emcc_step);
}
