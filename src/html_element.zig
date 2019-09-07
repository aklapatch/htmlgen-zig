const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Buffer = std.Buffer;
const testing = std.testing;
const ArrayList = std.ArrayList;
const HTMLAttribute = @import("html_attribute.zig").HTMLAttribute;

pub const TagContentTag = enum {
    Text,
    Element,
};
pub const TagContent = union(TagContentTag) {
    Text: Buffer,
    Element: HTMLElement,
};

pub const HTMLElement = struct {
    tag_name: Buffer,
    attributes: ArrayList(HTMLAttribute),
    content: ArrayList(TagContent),

    const Self = @This();

    pub fn init(alloc: *Allocator, tag_arg: []const u8) !Self {
        return Self{
            .tag_name = try Buffer.init(alloc, tag_arg),
            .content = ArrayList(TagContent).init(alloc),
            .attributes = ArrayList(HTMLAttribute).init(alloc),
        };
    }

    pub fn tagSlice(self: *Self) []u8 {
        return self.tag_name.toSliceConst();
    }

    pub fn appendContent(self: *Self, content_arg: TagContent) !void {
        try self.content.append(content_arg);
    }
    pub fn appendAttribute(self: *Self, attr_arg: HTMLAttribute) !void {
        try self.attributes.append(attr_arg);
    }

    pub fn deinit(self: *Self) void {
        self.tag_name.deinit();
        self.content.deinit();
        self.attributes.deinit();
    }

    // returns the name and value formatted like they should be in an html document`
    // this needs to be deallocated by the user after it is passed out
    // TODO: optimize this so that it gets the buffer size first, and then
    // copies in the characters
    pub fn formattedBuf(self: *const Self) error{OutOfMemory}!Buffer {
        var total_size: usize = 0;

        var output: Buffer = try Buffer.init(self.attributes.allocator, "<");
        try output.append(self.tag_name.toSliceConst());

        var attr_it = self.attributes.iterator();
        while (attr_it.next()) |attribute| {
            try output.append(" ");

            var attr_buf = try attribute.formattedBuf();
            try output.append(attr_buf.toSliceConst());

            attr_buf.deinit();
        }

        try output.append(">");

        var element_it = self.content.iterator();
        while (element_it.next()) |element| {
            switch (element) {
                TagContentTag.Text => try output.append(element.Text.toSliceConst()),
                TagContent.Element => {
                    var elem_buf = try element.Element.formattedBuf();
                    try output.append(elem_buf.toSliceConst());
                    elem_buf.deinit();
                },
            }
        }

        // if there is no content, then do not add the closing tag
        if (self.content.count() > 0) {
            //  add '</>' and the closing tag name
            try output.append("</");
            try output.append(self.tag_name.toSliceConst());
            try output.append(">");
        }

        return output;
    }
};

// TODO: write tests

test "HTMLElement init, slicing, formatting" {
    const name = "attrname";
    const value = "attrvalue";
    const format_str = "<p attrname='attrvalue'> test </p>";
    var test_attribute = try HTMLAttribute.init(std.debug.global_allocator, "attrname", "attrvalue");
    var t_element = try HTMLElement.init(std.debug.global_allocator, "p");
    defer t_element.deinit();
    defer test_attribute.deinit();

    try t_element.appendAttribute(test_attribute);
    try t_element.appendContent(TagContent{ .Text = Buffer.init(std.debug.global_allocator, " test ") });

    var test_str = try t_element.formattedBuf();
    defer test_str.deinit();
    testing.expectEqualSlices(u8, test_str.toSliceConst(), format_str);
}
