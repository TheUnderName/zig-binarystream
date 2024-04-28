const std = @import("std");
pub const binaryStream = struct {
    const Self = *@This();
    buff: std.ArrayList(u8),
    offset: usize,
    pub fn writeByte(self: Self, value: u8) !void {
        const arraybyte: [1]u8 = [_]u8{value};
        try self.write(arraybyte[0..1]);
    }
    pub fn writeStrL(self: Self, value: []const u8) !void {
        const arraybyte: []const u8 = value[0..];
        try self.write7BitEncodedInt(@as(usize, @intCast(arraybyte.len)));
        try self.write(arraybyte[0..]);
    }
    pub fn writeStrL8(self: Self, value: []const u8) !void {
        const arraybyte: []const u8 = value[0..];
        try self.writeByte(@as(u8, @intCast(arraybyte.len)));
        try self.write(arraybyte[0..]);
    }
    pub fn writeU16(self: Self, value: u16) !void {
        const byte = std.mem.toBytes(value);
        try self.write(byte[0..2]);
    }
    pub fn writeInt16(self: Self, value: i16) !void {
        const byte = std.mem.toBytes(value);
        try self.write(byte[0..2]);
    }
    pub fn write(self: Self, value: []const u8) !void {
        try self.buff.appendSlice(value);
    }
    pub fn writeInt32(self: Self, value: i32) !void {
        const byte = std.mem.toBytes(value);
        try self.write(byte[0..4]);
    }
    pub fn writeU64(self: Self, value: u64) !void {
        const byte = std.mem.toBytes(value);
        try self.write(byte[0..8]);
    }
    pub fn write7BitEncodedInt(self: Self, value: usize) !void {
        var num = value;
        while (num > 127) : (num >>= 7) {
            try self.writeByte(@as(u8, @truncate(num)) | 0x80);
        }
        try self.writeByte(@as(u8, @truncate(num)));
    }
    pub fn read(self: Self, size: usize) ![]u8 {
        const buffer: []u8 = self.buff.items[self.offset .. self.offset + size];
        self.offset += size;
        return buffer;
    }
    pub fn read7BitEncodedInt(self: Self) !usize {
        var num: usize = 0;
        var shift: u6 = 0;

        while (true) {
            const readd = try self.readByte();
            num |= @as(usize, readd & 0x7F) << shift;
            shift += 7;
            if (readd <= 127) break;
        }
        return num;
    }
    pub fn readStringL(self: Self) ![]u8 {
        const length = try self.read7BitEncodedInt();
        const buff = try self.read(length);
        return buff;
    }
    pub fn readStringL8(self: Self) ![]u8 {
        const length = try self.readByte();
        const buff = try self.read(length);
        return buff;
    }
    pub fn readByte(self: Self) !u8 {
        return (try self.read(1))[0];
    }
    pub fn readInt32(self: Self) !i32 {
        const arraybyte: []u8 = try self.read(4);
        var value: i32 = 0;
        value = (@as(i32, @intCast(arraybyte[0]))) | (@as(i32, @intCast(arraybyte[1])) << 8) | (@as(i32, @intCast(arraybyte[2])) << 16) | (@as(i32, @intCast(arraybyte[3])) << 24);
        return value;
    }
    pub fn readUInt64(self: Self) !u64 {
        const arraybyte: []u8 = try self.read(8);
        var value: u64 = 0;
        value = (@as(u64, @intCast(arraybyte[0]))) | (@as(u64, @intCast(arraybyte[1])) << 8) | (@as(u64, @intCast(arraybyte[2])) << 16) | (@as(u64, @intCast(arraybyte[3])) << 24) | (@as(u64, @intCast(arraybyte[4])) << 32) | (@as(u64, @intCast(arraybyte[5])) << 40) | (@as(u64, @intCast(arraybyte[6])) << 48) | (@as(u64, @intCast(arraybyte[7])) << 56);
        return value;
    }
    pub fn readU16(self: Self) !u16 {
        const arraybyte: []u8 = try self.read(2);
        var value: u16 = 0;
        value = (@as(u16, @intCast(arraybyte[1])) << 8) | @as(u16, @intCast(arraybyte[0]));
        return value;
    }
    pub fn read16(self: Self) !i16 {
        const arraybyte: []u8 = try self.read(2);
        var value: i16 = 0;
        value = (@as(i16, @intCast(arraybyte[1])) << 8) | @as(i16, @intCast(arraybyte[0]));
        return value;
    }
};
test "testing write" {
    var binary = binaryStream{ .buff = std.ArrayList(u8).init(std.heap.page_allocator), .offset = 0 };

    defer binary.buff.deinit();

    try binary.writeByte(1);
    try binary.writeStrL("Hello World");
    try binary.writeU16(500);
    try binary.writeInt32(200);
    try binary.writeU64(505);
    try binary.writeInt16(5000);
    try binary.writeStrL8("Hello World 2");

    std.debug.print(".{any}\n", .{binary.buff.items});

    _ = try binary.readByte();
    const var1: []u8 = try binary.readStringL();
    const var2: u16 = try binary.readU16();
    const var3: i32 = try binary.readInt32();
    const var4: u64 = try binary.readUInt64();
    const var5: i16 = try binary.read16();
    const var6: []u8 = try binary.readStringL8();

    std.debug.print("var 1 {}\n", .{std.unicode.fmtUtf8(var1)});
    std.debug.print("var 2 {d}\n", .{var2});
    std.debug.print("var 3 {d}\n", .{var3});
    std.debug.print("var 4 {d}\n", .{var4});
    std.debug.print("var 5 {d}\n", .{var5});
    std.debug.print("var 6 {}\n", .{std.unicode.fmtUtf8(var6)});
}
