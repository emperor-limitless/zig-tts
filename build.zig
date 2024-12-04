const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib = b.addModule("tts", .{ .root_source_file = b.path("src/root.zig") });
    var objectFile: []const u8 = "libs/macos/libtts.a";
    if (comptime builtin.target.os.tag == .windows) {
        objectFile = "libs/windows/tts.dll.lib";
        b.installBinFile("libs/windows/tts.dll", "tts.dll");
        b.installBinFile("libs/windows/nvdaControllerClient64.dll", "nvdaControllerClient64.dll");
        b.installBinFile("libs/windows/SAAPI64.dll", "SAAPI64.dll");
    } else {
        objectFile = "libs/linux/libtts.a";
    }
    lib.addObjectFile(.{ .cwd_relative = objectFile });
    lib.addIncludePath(.{
        .cwd_relative = "include/",
    });
    b.installLibFile(objectFile, objectFile);
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/eroot.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.addObjectFile(.{ .cwd_relative = objectFile });
    lib_unit_tests.linkLibC();
    lib_unit_tests.addIncludePath(.{
        .cwd_relative = "include/",
    });
    if (builtin.target.os.tag == .windows) {
        const bin_dir = b.pathJoin(&.{ b.install_prefix, "bin" });
        lib_unit_tests.addLibraryPath(.{ .cwd_relative = bin_dir });
    }
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
