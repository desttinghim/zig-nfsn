const std = @import("std");
const pkgs = @import("deps.zig").pkgs;

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const ddns_exe = b.addExecutable("nfsn-ddns", "src/nfsn-ddns.zig");
    pkgs.addAllTo(ddns_exe);
    ddns_exe.setTarget(target);
    ddns_exe.setBuildMode(mode);
    ddns_exe.install();

    const ddns_run_cmd = ddns_exe.run();
    ddns_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        ddns_run_cmd.addArgs(args);
    }

    const ddns_run_step = b.step("run-ddns", "Run the app");
    ddns_run_step.dependOn(&ddns_run_cmd.step);

    const inspect_exe = b.addExecutable("nfsn-inspect", "src/nfsn-inspect.zig");
    pkgs.addAllTo(inspect_exe);
    inspect_exe.setTarget(target);
    inspect_exe.setBuildMode(mode);
    inspect_exe.install();

    const inspect_run_cmd = inspect_exe.run();
    inspect_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        inspect_run_cmd.addArgs(args);
    }

    const inspect_run_step = b.step("run-inspect", "Run the app");
    inspect_run_step.dependOn(&inspect_run_cmd.step);
}
