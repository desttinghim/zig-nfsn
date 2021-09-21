const std = @import("std");
const Allocator = std.mem.Allocator;
const Client = @import("requestz").Client;
const Headers = @import("http").Headers;
const StatusCode = @import("http").StatusCode;
const Sha1 = std.crypto.hash.Sha1;
const Dir = std.fs.Dir;
const Response = @import("requestz").Response;

const Credentials = struct {
    user: []u8,
    apikey: []u8,

    pub fn load(alloc: *Allocator, dir: Dir, name: []const u8) !@This() {
        var fcred = try dir.readFileAlloc(alloc, name, 32 * 1024);
        defer alloc.free(fcred);

        var fcredtokens = std.json.TokenStream.init(fcred);
        var cred = std.json.parse(Credentials, &fcredtokens, .{ .allocator = alloc }) catch |e| {
            std.log.err("Incorrect credentials file. Fix and rerun.\n{s}", .{fcred});
            return e;
        };
        defer std.json.parseFree(Credentials, cred, .{ .allocator = alloc });

        // Not sure if cred will be valid after it is returned, so I'm duping everything
        return @This(){
            .user = try alloc.dupe(u8, cred.user),
            .apikey = try alloc.dupe(u8, cred.apikey),
        };
    }

    pub fn deinit(self: @This(), alloc: *Allocator) void {
        alloc.free(self.user);
        alloc.free(self.apikey);
    }
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

pub const RequestError = struct {
    @"error": []u8,
    debug: []u8,
};

pub const BodyType = enum { Empty, FormUrlEncoded };

pub const Body = union(BodyType) {
    Empty: void,
    FormUrlEncoded: []u8,

    pub fn as_string(self: @This()) []u8 {
        return switch (self) {
            .Empty => "",
            .FormUrlEncoded => self.FormUrlEncoded,
        };
    }
};

pub const DNSParam = struct {
    name: ?[]u8 = null,
    @"type": ?[]u8 = null,
    data: ?[]u8 = null,
};

pub const ParamBuilder = struct {
    alloc: *Allocator,
    string: []u8,

    pub fn init(alloc: *Allocator) @This() {
        return @This(){
            .alloc = alloc,
            .string = "",
        };
    }

    pub fn add(self: *@This(), name: []const u8, value: []const u8) !void {
        var new_string = if (self.string.len == 0)
            try std.fmt.allocPrintZ(self.alloc, "{s}={s}", .{ name, value })
        else
            try std.fmt.allocPrintZ(self.alloc, "{s}&{s}={s}", .{ self.string, name, value });
        self.alloc.free(self.string);
        self.string = new_string;
    }

    pub fn build(self: @This()) Body {
        return switch (self.string.len) {
            0 => BodyType.Empty,
            else => .{ .FormUrlEncoded = self.string },
        };
    }

    pub fn deinit(self: @This()) void {
        self.alloc.free(self.string);
    }
};

pub const DNS = struct {
    nfsn: *const NFSN,
    domain: []u8,

    pub fn init(nfsn: *const NFSN, domain: []u8) @This() {
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

        var body_string = try std.fmt.allocPrintZ(self.nfsn.alloc, "name={s}&type={s}&data={s}", .{ name, type_, data });
        defer self.nfsn.alloc.free(body_string);
        var body: Body = Body{ .FormUrlEncoded = body_string };

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

    pub fn addRR(self: @This(), name: []const u8, type_: []const u8, data: []const u8, ttl: u64) ![]const u8 {
        var uri = try std.fmt.allocPrintZ(self.nfsn.alloc, "/dns/{s}/addRR", .{self.domain});
        defer self.nfsn.alloc.free(uri);

        var body_string = try std.fmt.allocPrintZ(self.nfsn.alloc, "name={s}&type={s}&data={s}&ttl={}", .{ name, type_, data, ttl });
        defer self.nfsn.alloc.free(body_string);
        var body: Body = Body{ .FormUrlEncoded = body_string };

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

pub const NFSN = struct {
    address: []const u8 = "https://api.nearlyfreespeech.net",
    alloc: *Allocator,
    credentials: Credentials,
    client: *Client,

    // Provide credentials from memory
    pub fn init(alloc: *Allocator, client: *Client, credentials: Credentials) !@This() {
        return @This(){
            .alloc = alloc,
            .client = client,
            .credentials = credentials,
        };
    }

    // Load credentials from file
    pub fn initFromFile(alloc: *Allocator, client: *Client, dir: Dir, file: []const u8) !@This() {
        var cred = Credentials.load(alloc, dir, file) catch |e| {
            std.log.err("Could not open credential file! Create credentials.json next to the executable or pass the directory it is in through $CREDENTIALS_DIRECTORY", .{});
            return e;
        };
        return try NFSN.init(alloc, client, cred);
    }

    pub fn deinit(self: @This()) void {
        self.credentials.deinit(self.alloc);
    }

    pub fn dns(self: @This(), domain: []u8) DNS {
        return DNS.init(&self, domain);
    }

    // Takes a byte from 0-60 and turns it into a alphanumeric character
    // or just passes the value through
    fn make_char(b: u8) u8 {
        return switch (b) {
            0...9 => b + 48,
            10...35 => b + 65,
            36...60 => b + 97,
            else => b,
        };
    }

    fn gen_salt(rand: *std.rand.Random, out: *[16]u8) void {
        rand.bytes(out);
        for (out) |*value| {
            value.* = make_char(value.* % 60);
        }
    }

    fn get_login_string(self: @This(), uri: []const u8, body: []const u8) ![]u8 {
        var ts: std.os.timespec = undefined;
        try std.os.clock_gettime(std.os.CLOCK_REALTIME, &ts);
        const timestamp = ts.tv_sec;
        var body_hash: [20]u8 = undefined;
        Sha1.hash(body, &body_hash, .{});
        var salt: [16]u8 = undefined;
        gen_salt(std.crypto.random, &salt);

        var hash_string = try std.fmt.allocPrintZ(self.alloc, "{s};{};{s};{s};{s};{x}", .{
            self.credentials.user, // login
            timestamp, // timestamp
            salt, // salt
            self.credentials.apikey, // key
            uri, // request uri
            std.fmt.fmtSliceHexLower(&body_hash), // body hash
        });
        defer self.alloc.free(hash_string);

        var hash: [20]u8 = undefined;
        Sha1.hash(hash_string, &hash, .{});

        var login_string = try std.fmt.allocPrintZ(self.alloc, "{s};{};{s};{x}", .{
            self.credentials.user,
            timestamp,
            salt,
            std.fmt.fmtSliceHexLower(&hash),
        });

        return login_string;
    }

    pub fn post(self: *const @This(), uri: []u8, body: Body) !Response {
        var url = try std.fmt.allocPrintZ(self.alloc, "{s}{s}", .{ self.address, uri });
        defer self.alloc.free(url);

        var headers = Headers.init(self.alloc);
        defer headers.deinit();

        var login_string = try self.get_login_string(uri, body.as_string());
        defer self.alloc.free(login_string);

        try headers.append("X-NFSN-Authentication", login_string);
        switch (body) {
            .Empty => {},
            .FormUrlEncoded => {
                try headers.append("Content-Type", "application/x-www-form-urlencoded");
            },
        }

        return try self.client.post(url, .{ .headers = headers.items() });
    }
};
