const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;
const Buffer = std.Buffer;
const testing = std.testing;
const ArrayList = std.ArrayList;
const HTMLAttribute = @import("html_attribute.zig").HTMLAttribute;
const HTMLElement = @import("html_element.zig").HTMLElement;

const TagContent = @import("html_element.zig").TagContent;

pub const HTMLDoc = struct {
    doc_type: Buffer,
    elements: ArrayList(HTMLElement),

    const Self = @This();

    pub fn init(alloc: *Allocator, doc_type: []const u8) !Self {
        return Self{
            .doc_type = try Buffer.init(alloc, doc_type),
            .elements = ArrayList(HTMLElement).init(alloc),
        };
    }

    pub fn addElement(self: *Self, element: HTMLElement) !void {
        try self.elements.append(element);
    }

    pub fn formattedBuf(self: Self) !Buffer {
        // make the first part of the document
        var output = try Buffer.init(self.elements.allocator, "<!DOCTYPE ");
        try output.append(self.doc_type.toSliceConst());
        try output.append(">\n");

        var elements = self.elements.toSliceConst();

        for (elements) |element| {
            var elem_buf = try element.formattedBuf();
            try output.append(elem_buf.toSliceConst());

            elem_buf.deinit();
        }

        return output;
    }
};

test "HTMLDoc init, formatting" {
    const name = "attrname";
    const value = "attrvalue";
    const format_str = "<p attrname='attrvalue'> test </p>";

    var test_attribute = try HTMLAttribute.init(std.debug.global_allocator, "attrname", "attrvalue");
    var t_element = try HTMLElement.init(std.debug.global_allocator, "p");
    defer t_element.deinit();
    defer test_attribute.deinit();

    try t_element.appendAttribute(test_attribute);

    try t_element.appendContent(TagContent{ .Text = try Buffer.init(std.debug.global_allocator, " test ") });

    var t_doc = try HTMLDoc.init(std.debug.global_allocator, "html");
    const doc_str = "<!DOCTYPE html>\n" ++ format_str;

    try t_doc.addElement(t_element);

    var doc = try t_doc.formattedBuf();
    defer doc.deinit();

    testing.expectEqualSlices(u8, doc.toSliceConst(), doc_str);
}
