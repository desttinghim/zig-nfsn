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

    const argv = std.os.argv;

    if (argv.len > 3) {
        const arg1 = std.mem.span(argv[1]);

        var result: []const u8 = "No result";
        defer alloc.free(result);
        if (std.mem.eql(u8, "member", arg1)) {
            const arg2 = std.mem.span(argv[2]);
            const member = nfsn.member(arg2);

            const arg3 = std.mem.span(argv[3]);
            if (std.mem.eql(u8, "get_accounts", arg3)) {
                result = try member.get_accounts();
            } else if (std.mem.eql(u8, "get_sites", arg3)) {
                result = try member.get_sites();
            } else {
                result = "No such method or property";
            }
        } else if (std.mem.eql(u8, "account", arg1)) {
            const arg2 = std.mem.span(argv[2]);
            const account = nfsn.account(arg2);

            const arg3 = std.mem.span(argv[3]);
            if (std.mem.eql(u8, "get_balance", arg3)) {
                result = try account.get_balance();
            } else if (std.mem.eql(u8, "get_balanceCash", arg3)) {
                result = try account.get_balanceCash();
            } else if (std.mem.eql(u8, "get_balanceCredit", arg3)) {
                result = try account.get_balanceCredit();
            } else if (std.mem.eql(u8, "get_balanceHigh", arg3)) {
                result = try account.get_balanceHigh();
            } else if (std.mem.eql(u8, "get_balanceCash", arg3)) {
                result = try account.get_balanceCash();
            } else if (std.mem.eql(u8, "get_status", arg3)) {
                result = try account.get_status();
            } else if (std.mem.eql(u8, "get_sites", arg3)) {
                result = try account.get_sites();
            } else {
                result = "No such method or property";
            }
        } else {
            result = "Does not exist.";
        }

        std.log.info("{s}", .{result});
    } else {
        std.log.info("Not enough arguments.", .{});
    }

    // var account = nfsn.member("desttinghim").account();

    // var a = nfsn.account
}
