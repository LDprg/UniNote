const std = @import("std");

pub const std_options = .{
    .logFn = customLogFn,
};

const Color = enum {
    Red,
    Green,
    Yellow,
    Magenta,
    Cyan,
    Blue,
    Reset,
};

pub fn customLogFn(
    comptime level: std.log.Level,
    comptime _: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = comptime getLevelColor(level) ++ "[" ++ level.asText() ++ "]" ++ getColor(Color.Reset) ++ " ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}

fn getLevelColor(level: std.log.Level) []const u8 {
    return switch (level) {
        .debug => getColor(Color.Blue),
        .info => getColor(Color.Green),
        .warn => getColor(Color.Yellow),
        .err => getColor(Color.Red),
    };
}

fn getColor(color: Color) []const u8 {
    return switch (color) {
        .Red => "\x1b[31m",
        .Green => "\x1b[32m",
        .Yellow => "\x1b[33m",
        .Magenta => "\x1b[35m",
        .Cyan => "\x1b[36m",
        .Blue => "\x1b[34m",
        .Reset => "\x1b[0m",
    };
}
