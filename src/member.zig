const std = @import("std");
const Allocator = std.mem.Allocator;
const Client = @import("requestz").Client;
const Headers = @import("http").Headers;
const StatusCode = @import("http").StatusCode;
const Sha1 = std.crypto.hash.Sha1;
const Dir = std.fs.Dir;
const Response = @import("requestz").Response;
const nfsnlib = @import("nfsn.zig");
const NFSN = nfsnlib.NFSN;
const ParamBuilder = nfsnlib.ParamBuilder;
const Body = nfsnlib.Body;

pub const Member = struct {
    nfsn: *const NFSN,
    member: []const u8,

    pub fn init(nfsn: *const NFSN, member: []const u8) @This() {
        return @This(){
            .nfsn = nfsn,
            .member = member,
        };
    }

    pub fn get_accounts(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/member/{s}/accounts", .{self.member});
        defer self.nfsn.alloc.free(uri);
        const body: Body = .Empty;

        var response = try self.nfsn.get(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return try self.nfsn.alloc.dupe(u8, response.body);
            },
            else => {
                std.log.err("Unexpected response: {s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }

    pub fn get_sites(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/member/{s}/sites", .{self.member});
        defer self.nfsn.alloc.free(uri);
        const body: Body = .Empty;

        var response = try self.nfsn.get(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return try self.nfsn.alloc.dupe(u8, response.body);
            },
            else => {
                std.log.err("Unexpected response: {s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }

    pub fn getInfo(self: @This()) ![]u8 {
        @compileError("Member getInfo is unimplemented by NFSN at time of writing. Contact support to get it implemented.");
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/member/{s}/getInfo", .{self.member});
        defer self.nfsn.alloc.free(uri);
        const body: Body = .Empty;

        var response = try self.nfsn.post(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return try self.nfsn.alloc.dupe(u8, response.body);
            },
            else => {
                std.log.err("Unexpected response: {s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }
};
