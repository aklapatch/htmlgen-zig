const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const attribute_lib = b.addStaticLibrary("attribute", "src/html_attribute.zig");
    attribute_lib.setBuildMode(mode);
    attribute_lib.install();

    const element_lib = b.addStaticLibrary("element", "src/html_element.zig");
    element_lib.setBuildMode(mode);
    element_lib.install();

    const doc_lib = b.addStaticLibrary("doc", "src/html_doc.zig");
    doc_lib.setBuildMode(mode);
    doc_lib.install();

    var debugexec = b.addExecutable("debugexec", "src/debugexec.zig");
    debugexec.setBuildMode(mode);
    debugexec.install();

    var tests = b.addTest("src/html_doc.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);
}
