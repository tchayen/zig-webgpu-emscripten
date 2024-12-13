const std = @import("std");

const zemscripten = @import("zemscripten");
pub const panic = zemscripten.panic;

pub const std_options = std.Options{
    .logFn = zemscripten.log,
};

export fn main() c_int {
    std.log.info("hello, world.", .{});
    zemscripten.log(.info, .default, "hello, world.", .{});
    return 0;
}
