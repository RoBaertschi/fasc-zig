const Token = @import("Token.zig");
const TokenType = Token.TokenType;
const Self = @This();

input: []u8,
position: u32,
readPosition: u32,
ch: u8,
allocator: std.mem.Allocator,
/// The allocator used for the tokens.
token_allocator: std.mem.Allocator,

/// Lexer allocates space on the heap for input and then copies it to that. So input does not need to presist.
/// The tokens are allocated using the same allocator.
pub fn init(allocator: std.mem.Allocator, input: []u8) std.mem.Allocator.Error!Self {
    return initTokenAlloc(allocator, allocator, input);
}

/// Create a Lexer using two seperate allocators for the token and itself
pub fn initTokenAlloc(allocator: std.mem.Allocator, token_allocator: std.mem.Allocator, input: []u8) std.mem.Allocator.Error!Self {
    // Make a copy of input in our own managed memory, so that we own the input.
    const allocatedInput = try allocator.alloc(u8, input.len);
    std.mem.copyForwards(u8, allocatedInput, input);

    var l = Self{
        .input = allocatedInput,
        .readPosition = 0,
        .position = 0,
        .ch = 0,
        .allocator = allocator,
        .token_allocator = token_allocator,
    };
    l.readChar();
    return l;
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.input);
}

pub fn nextToken(self: *Self) std.mem.Allocator.Error!Token {
    var tok: Token = undefined;

    self.skipWhitespace();

    switch (self.ch) {
        0 => {
            tok = try self.newTokenStr(TokenType.eof, "");
        },
        '-' => tok = try self.newToken(TokenType.minus, self.ch),
        '+' => tok = try self.newToken(TokenType.plus, self.ch),
        '*' => tok = try self.newToken(TokenType.asterisk, self.ch),
        '/' => tok = try self.newToken(TokenType.slash, self.ch),
        else => {
            if (isDigit(self.ch)) {
                // We return because we already consumed the char
                return self.newTokenStr(TokenType.int, self.readNumber());
            } else if (isLetter(self.ch)) {
                return self.newTokenStr(TokenType.ident, self.readIdentifier());
            }

            tok = try self.newToken(TokenType.illegal, self.ch);
        },
    }

    self.readChar();
    return tok;
}

fn readChar(self: *Self) void {
    if (self.readPosition >= self.input.len) {
        self.ch = 0;
    } else {
        self.ch = self.input[self.readPosition];
    }

    self.position = self.readPosition;
    self.readPosition += 1;
}

fn peekChar(self: *Self) u8 {
    if (self.readPosition >= self.input.len) {
        return 0;
    } else {
        return self.input[self.readPosition];
    }
}

/// Allocates a new token using the allocator from self.
fn newToken(self: *Self, token_type: Token.TokenType, ch: u8) std.mem.Allocator.Error!Token {
    return Token.fromCharacter(self.token_allocator, token_type, ch);
}

fn newTokenStr(self: *Self, token_type: TokenType, literal: []const u8) std.mem.Allocator.Error!Token {
    return Token.fromString(self.token_allocator, token_type, literal);
}

fn isDigit(ch: u8) bool {
    return '0' <= ch and ch <= '9';
}

fn isLetter(ch: u8) bool {
    return ('a' <= ch and ch <= 'z') or ('a' <= ch and ch <= 'z') or ch == '_';
}

fn isWhitespace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn skipWhitespace(self: *Self) void {
    while (isWhitespace(self.ch)) {
        self.readChar();
    }
}

fn readNumber(self: *Self) []u8 {
    const pos = self.position;
    while (isDigit(self.ch)) {
        self.readChar();
    }
    return self.input[pos..self.position];
}

fn readIdentifier(self: *Self) []u8 {
    const pos = self.position;
    while (isLetter(self.ch)) {
        self.readChar();
    }
    return self.input[pos..self.position];
}

const std = @import("std");
const testing = std.testing;

test "test memory" {
    var input = "1".*;
    var lexer = try Self.init(testing.allocator, &input);
    defer lexer.deinit();
}

test "different allocators for tokens and lexer" {
    var input = "33".*;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lexer = try Self.initTokenAlloc(testing.allocator, allocator, &input);
    defer lexer.deinit();

    const tok = try lexer.nextToken();
    tok.deinit();
    try testing.expect(!gpa.detectLeaks());
}

test "test tokens" {
    var input =
        \\12 + 12
        \\hello + 2
    .*;

    const Test = struct {
        expectedType: TokenType,
        expectedLiteral: []const u8,
    };

    const tests = [_]Test{
        .{ .expectedType = TokenType.int, .expectedLiteral = "12" },
        .{ .expectedType = TokenType.plus, .expectedLiteral = "+" },
        .{ .expectedType = TokenType.int, .expectedLiteral = "12" },
        .{ .expectedType = TokenType.ident, .expectedLiteral = "hello" },
        .{ .expectedType = TokenType.plus, .expectedLiteral = "+" },
        .{ .expectedType = TokenType.int, .expectedLiteral = "2" },
        .{ .expectedType = TokenType.eof, .expectedLiteral = "" },
    };
    var lexer = try Self.init(testing.allocator, &input);
    defer lexer.deinit();

    for (tests, 0..) |t, index| {
        _ = index;

        const tok = try lexer.nextToken();
        defer tok.deinit();

        try testing.expectEqual(t.expectedType, tok.type);
        try testing.expectEqualStrings(t.expectedLiteral, tok.literal);
    }
}

test "create should be initalized correctly" {
    var string = "hello".*;
    var lexer = try Self.init(testing.allocator, &string);
    defer lexer.deinit();
    try testing.expectEqual(lexer.position, 0);
    try testing.expectEqual(lexer.readPosition, 1);
    try testing.expectEqual(lexer.ch, 'h');
    try testing.expect(std.mem.eql(u8, lexer.input, "hello"));
}

test "lex an number" {
    var string = "12".*;
    var lexer = try Self.init(testing.allocator, &string);
    defer lexer.deinit();
    try testing.expectEqualStrings(&string, lexer.readNumber());
}
