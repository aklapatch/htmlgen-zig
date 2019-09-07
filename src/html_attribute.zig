const std = @import("std");
const warn = std.debug.warn;
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Buffer = std.Buffer;
const testing = std.testing;

pub const HTMLAttribute = struct {
    name: Buffer,
    value: Buffer,

    const Self = @This();

    pub fn init(alloc: *Allocator, name_arg: []const u8, value_arg: []const u8) !Self {
        return Self{
            .name = try Buffer.init(alloc, name_arg),
            .value = try Buffer.init(alloc, value_arg),
        };
    }

    pub fn nameSlice(self: Self) []u8 {
        return self.name.toSliceConst();
    }

    pub fn valueSlice(self: Self) []u8 {
        return self.value.toSliceConst();
    }
    pub fn deinit(self: *Self) void {
        self.name.deinit();
        self.value.deinit();
    }

    // returns the name and value formatted like they should be in an html document`
    // this needs to be deallocated by the user after it is passed out
    // TODO: optimize this so that it gets the buffer size first, and then
    // copies in the characters
    pub fn formattedBuf(self: Self) !Buffer {
        var output = try Buffer.init(self.name.list.allocator, self.nameSlice());
        try output.append("='");
        try output.append(self.valueSlice());
        try output.append("'");
        return output;
    }
};

test "HTMLAttribute init, slicing, formatting" {
    const name = "attrname";
    const value = "attrvalue";
    const format_str = "attrname='attrvalue'";
    var test_attribute = try HTMLAttribute.init(std.debug.global_allocator, "attrname", "attrvalue");
    defer test_attribute.deinit();

    warn("\n\ntesting name and value slicing\n");
    testing.expectEqualSlices(u8, name, test_attribute.nameSlice());
    testing.expectEqualSlices(u8, value, test_attribute.valueSlice());
    warn("passed\n");

    var test_str = try test_attribute.formattedBuf();
    defer test_str.deinit();
    warn("\ntesting string formatting\n");

    testing.expectEqualSlices(u8, test_str.toSliceConst(), format_str);

    warn("passed\n\n");
}
