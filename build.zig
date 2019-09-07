const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const attribute_lib = b.addStaticLibrary("htmlgen-zig", "src/html_attribute.zig");
    attribute_lib.setBuildMode(mode);
    attribute_lib.install();

    const element_lib = b.addStaticLibrary("element", "src/html_element.zig");
    element_lib.setBuildMode(mode);
    element_lib.install();

    var attribute_tests = b.addTest("src/html_attribute.zig");
    attribute_tests.setBuildMode(mode);

    var debugexec = b.addExecutable("debugexec", "src/debugexec.zig");
    debugexec.setBuildMode(mode);
    debugexec.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&attribute_tests.step);

    var element_tests = b.addTest("src/html_element.zig");
    element_tests.setBuildMode(mode);

    test_step.dependOn(&element_tests.step);
}
