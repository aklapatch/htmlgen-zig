const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Buffer = std.Buffer;
const testing = std.testing;
const ArrayList = std.ArrayList;
const HTMLAttribute = @import("html_attribute.zig").HTMLAttribute;
const HTMLElement = @import("html_element.zig").HTMLElement;
const TagContent = @import("html_element.zig").TagContent;

pub fn main() !void {
    const name = "attrname";
    const value = "attrvalue";
    const format_str = "<p attrname='attrvalue'> test </p>";
    var test_attribute = try HTMLAttribute.init(std.debug.global_allocator, "attrname", "attrvalue");
    var t_element = try HTMLElement.init(std.debug.global_allocator, "p");
    defer t_element.deinit();
    defer test_attribute.deinit();

    try t_element.appendAttribute(test_attribute);
    try t_element.appendContent(TagContent{ .Text = try Buffer.init(std.debug.global_allocator, " test ") });

    var test_str = try t_element.formattedBuf();
    defer test_str.deinit();
    testing.expectEqualSlices(u8, test_str.toSliceConst(), format_str);
}
