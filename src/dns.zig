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

pub const DNSParam = struct {
    name: ?[]u8 = null,
    @"type": ?[]u8 = null,
    data: ?[]u8 = null,
};

pub const RR = struct {
    name: []u8,
    @"type": []u8,
    data: []u8,
    ttl: u64,
    scope: []u8,

    pub fn dupe(self: @This(), alloc: *Allocator) !@This() {
        return @This(){
            .name = try alloc.dupe(u8, self.name),
            .@"type" = try alloc.dupe(u8, self.@"type"),
            .data = try alloc.dupe(u8, self.data),
            .ttl = self.ttl,
            .scope = try alloc.dupe(u8, self.scope),
        };
    }

    pub fn deinit(self: @This(), alloc: *Allocator) void {
        alloc.free(self.name);
        alloc.free(self.@"type");
        alloc.free(self.data);
        alloc.free(self.scope);
    }
};

pub const RRList = struct {
    alloc: *Allocator,
    body: []u8,
    list: []RR,

    pub fn parse(alloc: *Allocator, body: []u8) !@This() {
        var tokens = std.json.TokenStream.init(body);
        var rrlist = try std.json.parse([]RR, &tokens, .{ .allocator = alloc });
        return @This(){
            .alloc = alloc,
            .body = body,
            .list = rrlist,
        };
    }

    pub fn deinit(self: @This()) void {
        std.json.parseFree([]RR, self.list, .{ .allocator = self.alloc });
        self.alloc.free(self.body);
    }
};

pub const DNS = struct {
    nfsn: *const NFSN,
    domain: []const u8,

    pub fn init(nfsn: *const NFSN, domain: []const u8) @This() {
        return @This(){
            .nfsn = nfsn,
            .domain = domain,
        };
    }

    pub fn listRRs(self: @This(), opt: DNSParam) !RRList {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/dns/{s}/listRRs", .{self.domain});
        defer self.nfsn.alloc.free(uri);

        var params = ParamBuilder.init(self.nfsn.alloc);
        defer params.deinit();
        if (opt.name) |name| try params.add("name", name);
        if (opt.@"type") |type_| try params.add("type", type_);
        if (opt.data) |data| try params.add("data", data);
        const body: Body = params.build();

        var response = try self.nfsn.post(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return RRList.parse(self.nfsn.alloc, try self.nfsn.alloc.dupe(u8, response.body));
            },
            else => {
                std.log.err("Unexpected response: {s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }

    pub fn removeRR(self: @This(), name: []const u8, type_: []const u8, data: []const u8) !void {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/dns/{s}/removeRR", .{self.domain});
        defer self.nfsn.alloc.free(uri);

        var params = ParamBuilder.init(self.nfsn.alloc);
        defer params.deinit();
        try params.add("name", name);
        try params.add("type", type_);
        try params.add("data", data);
        var body: Body = params.build();

        var response = try self.nfsn.post(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return;
            },
            else => {
                std.log.err("{s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }

    pub fn addRR(self: @This(), name: []const u8, type_: []const u8, data: []const u8, ttl: u64) !void {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/dns/{s}/addRR", .{self.domain});
        defer self.nfsn.alloc.free(uri);

        var params = ParamBuilder.init(self.nfsn.alloc);
        defer params.deinit();
        try params.add("name", name);
        try params.add("type", type_);
        try params.add("data", data);
        try params.addInt("ttl", ttl);
        var body: Body = params.build();

        var response = try self.nfsn.post(uri, body);
        defer response.deinit();

        switch (response.status) {
            .Ok => {
                return;
            },
            else => {
                std.log.err("{s}", .{response.body});
                return error.NFSN_API_ERROR;
            },
        }
    }
};
