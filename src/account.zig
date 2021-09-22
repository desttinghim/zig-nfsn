const std = @import("std");
const Allocator = std.mem.Allocator;
const StatusCode = @import("http").StatusCode;
const Response = @import("requestz").Response;
const nfsnlib = @import("nfsn.zig");
const NFSN = nfsnlib.NFSN;
const ParamBuilder = nfsnlib.ParamBuilder;
const Body = nfsnlib.Body;

pub const Account = struct {
    nfsn: *const NFSN,
    account: []const u8,

    pub fn init(nfsn: *const NFSN, account: []const u8) @This() {
        return @This(){
            .nfsn = nfsn,
            .account = account,
        };
    }

    // Properties
    pub fn get_balance(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/balance", .{self.account});
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

    pub fn get_balanceCash(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/balanceCash", .{self.account});
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

    pub fn get_balanceCredit(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/balanceCredit", .{self.account});
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

    pub fn get_balanceHigh(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/balanceHigh", .{self.account});
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

    pub fn get_friendlyName(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/friendlyName", .{self.account});
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

    pub fn get_status(self: @This()) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/status", .{self.account});
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
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/sites", .{self.account});
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

    // Methods
    pub fn addSite(self: @This(), site: []const u8) ![]u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/account/{s}/addSite", .{self.account});
        defer self.nfsn.alloc.free(uri);

        var params = ParamsBuilder.init(self.nfsn.alloc);
        defer params.deinit();
        params.add("site", site);
        const body: Body = params.build();

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
