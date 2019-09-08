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

    pub fn tagSlice(self: Self) []u8 {
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

    pub fn formattedBufSize(self: Self) usize {
        var buff_size: usize = 0;
        buff_size += self.tag_name.len() + "<>\n".len;

        var attr_it = self.attributes.toSliceConst();
        for (attr_it) |attr| {
            buff_size += " ".len + attr.formattedBufSize();
        }

        var contents = self.content.toSliceConst();
        for (contents) |element| {
            switch (element) {
                TagContentTag.Text => buff_size += element.Text.len(),
                TagContent.Element => buff_size += element.Element.formattedBufSize(),
            }
        }
        if (self.content.count() > 0)
            buff_size += "</>\n".len + self.tag_name.len();

        return buff_size;
    }

    // returns the name and value formatted like they should be in an html document`
    // this needs to be deallocated by the user after it is passed out
    pub fn formattedBuf(self: Self) error{OutOfMemory}!Buffer {
        var output = Buffer.initNull(self.attributes.allocator);
        try output.list.ensureCapacity(self.formattedBufSize());

        try output.replaceContents("<");

        try output.append(self.tagSlice());

        var attr_it = self.attributes.toSliceConst();
        for (attr_it) |attribute| {
            try output.append(" ");

            var attr_buf = try attribute.formattedBuf();
            try output.append(attr_buf.toSliceConst());

            attr_buf.deinit();
        }

        try output.append(">");

        var contents = self.content.toSliceConst();
        for (contents) |element| {
            switch (element) {
                TagContentTag.Text => try output.append(element.Text.toSliceConst()),
                TagContent.Element => {
                    var elem_buf = try element.Element.formattedBuf();
                    try output.append(elem_buf.toSliceConst());
                    elem_buf.deinit();
                },
            }
        }

        //if there is no content, then do not add the closing tag
        if (self.content.count() > 0) {
            //add '</>' and the closing tag name
            try output.append("</");
            try output.append(self.tag_name.toSliceConst());
            try output.append(">\n");
        }
        return output;
    }
};

// TODO: write tests

test "HTMLElement init, slicing, formatting" {
    const name = "attrname";
    const value = "attrvalue";
    const format_str = "<p attrname='attrvalue'> test </p>\n";
    var test_attribute = try HTMLAttribute.init(std.debug.global_allocator, "attrname", "attrvalue");
    var t_element = try HTMLElement.init(std.debug.global_allocator, "p");
    defer t_element.deinit();
    defer test_attribute.deinit();

    try t_element.appendAttribute(test_attribute);

    try t_element.appendContent(TagContent{ .Text = try Buffer.init(std.debug.global_allocator, " test ") });

    var test_str = try t_element.formattedBuf();
    defer test_str.deinit();
    std.debug.warn("str = {}\n", test_str.toSliceConst());

    testing.expectEqualSlices(u8, test_str.toSliceConst(), format_str);
}
