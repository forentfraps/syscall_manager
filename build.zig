const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const lib_mod = b.addModule("syscall_manager", .{
        .root_source_file = b.path("src/syscall_manager.zig"),
        .target = target,
        .optimize = optimize,
    });
    const asm_object_dir = b.makeTempPath();

    var key: u64 = undefined;
    std.crypto.random.bytes(@as([*]u8, @ptrCast(&key))[0..8]);
    var prng = std.Random.DefaultPrng.init(key);
    var random = prng.random();
    const random_number = random.intRangeAtMost(u64, 0x10000000, 0xffffffff);
    const asm_string_object_name = std.fmt.allocPrint(
        std.heap.page_allocator,
        "{x}.o",
        .{random_number},
    ) catch @panic("OOM");

    const asm_object_file =
        b.pathJoin(&[_][]const u8{
            asm_object_dir,
            asm_string_object_name,
        });

    const asm_file_path =
        b.path("src/syscall_wrapper.asm").getPath3(b, null).toString(std.heap.page_allocator) catch {
            @panic("OOM");
        };
    _ = std.process.Child.run(.{
        .argv = &[_][]const u8{
            "nasm",
            "-f",
            "win64",
            asm_file_path,
            "-o",
            asm_object_file,
        },
        .allocator = std.heap.page_allocator,
    }) catch |e| {
        std.debug.print("Asm build failed -> {}\n", .{e});
        return;
    };

    lib_mod.addObjectFile(std.Build.LazyPath{ .cwd_relative = asm_object_file });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "syscall_manager",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);
}
