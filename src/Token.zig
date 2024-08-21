const std = @import("std");
const Self = @This();

pub const TokenType = enum {
    illegal,
    eof,

    // Literals and identifiers
    ident,
    int,

    // Keywords
    function,
};

const keywords = std.StaticStringMap(TokenType).initComptime(.{.{ "fn", TokenType.function }});

pub fn lookupIdent(ident: []const u8) TokenType {
    return keywords.get(ident) orelse return TokenType.ident;
}

type: TokenType,
literal: []u8,
allocator: std.mem.Allocator,

/// The literal has to be allocated with the same allocator passed to this function.
pub fn fromOwnedSlice(allocator: std.mem.Allocator, token_type: TokenType, literal: []u8) Self {
    return Self{
        .allocator = allocator,
        .type = token_type,
        .literal = literal,
    };
}

pub fn fromCharacter(allocator: std.mem.Allocator, token_type: TokenType, ch: u8) std.mem.Allocator.Error!Self {
    var allocatedLiteral = try allocator.alloc(u8, 1);
    allocatedLiteral[0] = ch;

    return Self{
        .allocator = allocator,
        .type = token_type,
        .literal = allocatedLiteral,
    };
}

pub fn fromString(allocator: std.mem.Allocator, token_type: TokenType, literal: []const u8) std.mem.Allocator.Error!Self {
    const allocatedLiteral = try allocator.alloc(u8, literal.len);
    std.mem.copyForwards(u8, allocatedLiteral, literal);

    return Self{
        .allocator = allocator,
        .type = token_type,
        .literal = allocatedLiteral,
    };
}

pub fn deinit(self: Self) void {
    std.debug.print("{s}", .{self.literal});
    self.allocator.free(self.literal);
}
