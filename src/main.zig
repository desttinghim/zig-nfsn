const std = @import("std");
const Allocator = std.mem.Allocator;
const Client = @import("requestz").Client;
const nfsnlib = @import("nfsn.zig");
const NFSN = nfsnlib.NFSN;
const Dir = std.fs.Dir;

// Config
const Config = struct {
    domain: []u8,
    subdomain: []u8,
    @"type": []u8,
    ttl: u64,

    pub fn load(alloc: *Allocator, dir: Dir, name: []const u8) !@This() {
        var fconf = try dir.readFileAlloc(alloc, name, 32 * 1024);
        defer alloc.free(fconf);

        var fconftokens = std.json.TokenStream.init(fconf);
        var config = std.json.parse(Config, &fconftokens, .{ .allocator = alloc }) catch |e| {
            std.log.err("Incorrect config. Fix and rerun.\n{s}", .{fconf});
            return e;
        };
        defer std.json.parseFree(Config, config, .{ .allocator = alloc });

        // Not sure if config will be valid after it is returned, so I'm duping everything
        return @This(){
            .domain = try alloc.dupe(u8, config.domain),
            .subdomain = try alloc.dupe(u8, config.subdomain),
            .@"type" = try alloc.dupe(u8, config.@"type"),
            .ttl = config.ttl,
        };
    }

    pub fn deinit(self: @This(), alloc: *Allocator) void {
        alloc.free(self.domain);
        alloc.free(self.subdomain);
        alloc.free(self.@"type");
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = &gpa.allocator;

    var configDir: Dir = std.fs.cwd();
    if (std.os.getenv("CONFIG_DIRECTORY")) |config_directory| {
        configDir = try std.fs.openDirAbsolute(config_directory, .{});
    }

    var credentialsDir: Dir = std.fs.cwd();
    if (std.os.getenv("CREDENTIALS_DIRECTORY")) |credentials_directory| {
        credentialsDir = try std.fs.openDirAbsolute(credentials_directory, .{});
    }

    var config = Config.load(alloc, configDir, "ddns.json") catch |e| {
        std.log.err("Could not open config file! Create config.json in the working directory or pass its location through $CONFIG_DIRECTORY", .{});
        return e;
    };
    defer config.deinit(alloc);

    std.log.info("DDNS update script running for {s}.{s}", .{ config.subdomain, config.domain });

    var client = try Client.init(alloc);
    defer client.deinit();

    var nfsn = try NFSN.initFromFile(alloc, &client, credentialsDir, "credentials.json");
    defer nfsn.deinit();

    // Get current ip
    var currentip = try getip(alloc, client);
    defer alloc.free(currentip);

    // Get nfsn dns ip
    var rrlist = try nfsn.dns(config.domain).listRRs();
    defer alloc.free(rrlist);
    defer for (rrlist) |record| record.deinit(alloc);

    // std.log.info("{any}", .{rrlist});
    for (rrlist) |record| {
        std.log.info("Current record: {s}, {s}, {s}, {}, {s}", .{ record.name, record.@"type", record.data, record.ttl, record.scope });
    }
    // var nfsnRRstring = try nfsn.dns(config.domain).listRRs();
    // defer alloc.free(nfsnRRstring);
    // std.log.info("{s}", .{nfsnRRstring});

    // var nfsnRRTokens = std.json.TokenStream.init(nfsnRRstring);
    // var result = std.json.parse(RequestResult, &nfsnRRTokens, .{ .allocator = alloc }) catch {
    //     std.log.err("{s}", .{nfsnRRstring});
    //     return error.API;
    // };
    // defer std.json.parseFree(RequestResult, result, .{ .allocator = alloc });
    // var listedip_opt: ?RR = null;
    // switch (result) {
    //     ResultType.err => |err| {
    //         std.log.err("{s}", .{err.@"error"});
    //         std.log.debug("{s}", .{err.debug});
    //     },
    //     ResultType.rr => |nfsnRR| {
    //         for (nfsnRR) |record| {
    //             if (std.mem.eql(u8, subdomain, record.name)) {
    //                 listedip_opt = record;
    //                 std.log.info("Current record: {s}, {s}, {s}, {}, {s}", .{ record.name, record.@"type", record.data, record.ttl, record.scope });
    //             }
    //         }

    //         if (listedip_opt) |listedip| {
    //             if (!std.mem.eql(u8, currentip, listedip.data) or record_ttl != listedip.ttl or !std.mem.eql(u8, record_type, listedip.@"type")) {
    //                 var remove = try nfsn_removeRR(alloc, client, listedip.name, listedip.@"type", listedip.data);
    //                 defer alloc.free(remove);
    //                 var add = try nfsn_addRR(alloc, client, subdomain, record_type, currentip, record_ttl);
    //                 defer alloc.free(add);
    //                 std.log.info("New record: {s}, {s}, {s}, {}", .{ subdomain, record_type, currentip, record_ttl });
    //                 std.log.notice("IP for {s}.{s} changed to {s}", .{ subdomain, domain, currentip });
    //             } else {
    //                 std.log.notice("No DNS update required.", .{});
    //             }
    //         } else {
    //             std.log.warn("DNS record does not exist!", .{});
    //             var add = try nfsn_addRR(alloc, client, subdomain, record_type, currentip, record_ttl);
    //             defer alloc.free(add);
    //             std.log.notice("Made DNS record for {s}.{s} point to {s}", .{ subdomain, domain, currentip });
    //         }
    //     },
    // }
}

pub fn getip(alloc: *Allocator, client: Client) ![]const u8 {
    var response = try client.get("http://api.ipify.org", .{});
    defer response.deinit();

    var ip = try alloc.dupe(u8, response.body);
    return ip;
}
