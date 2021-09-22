const std = @import("std");
const Allocator = std.mem.Allocator;
const Client = @import("requestz").Client;
const nfsnlib = @import("nfsn.zig");
const NFSN = nfsnlib.NFSN;
const Dir = std.fs.Dir;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = &gpa.allocator;

    // Create requestz client
    var client = try Client.init(alloc);
    defer client.deinit();

    // Init the NFSN api object
    var credentialsDir: Dir = std.fs.cwd();
    if (std.os.getenv("CREDENTIALS_DIRECTORY")) |credentials_directory| {
        credentialsDir = try std.fs.openDirAbsolute(credentials_directory, .{});
    }

    var nfsn = try NFSN.initFromFile(alloc, &client, credentialsDir, "credentials.json");
    defer nfsn.deinit();

    // var memberGetInfo = try nfsn.member("desttinghim").getInfo();
    // std.log.info("{s}", .{memberGetInfo});

    var accounts = try nfsn.member("desttinghim").get_accounts();
    defer alloc.free(accounts);
    std.log.info("{s}", .{accounts});

    var sites = try nfsn.member("desttinghim").get_sites();
    defer alloc.free(sites);
    std.log.info("{s}", .{sites});
}
