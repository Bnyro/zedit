const std = @import("std");
const capy = @import("capy");

var text = capy.DataWrapper([]const u8).of("");
var fileName = capy.DataWrapper([]const u8).of("foo.txt");

pub fn main() !void {
    try capy.init();

    var window = try capy.Window.init();

    var monospace = capy.DataWrapper(bool).of(false);

    var textArea = capy.TextArea(.{}).bind("monospace", &monospace).bind("text", &text);
    textArea.setText("Hello World!");

    const margin = capy.Rectangle.init(10, 10, 10, 10);

    try window.set(capy.Column(.{ .spacing = 0 }, .{
        capy.Expanded(capy.Margin(margin, &textArea)),
        capy.Margin(margin, capy.Align(.{}, capy.Row(.{}, .{ capy.CheckBox(.{ .label = "Monospaced" })
            .bind("checked", &monospace), capy.TextField(.{ .text = "foo.txt" }).bind("text", &fileName), capy.Button(.{ .label = "Save", .onclick = &saveBtn }) }))),
    }));

    window.setMenuBar(capy.MenuBar(.{
        capy.Menu(.{ .label = "File" }, .{
            capy.MenuItem(.{ .label = "Save", .onClick = &save }),
            capy.MenuItem(.{ .label = "Delete", .onClick = &delete }),
            capy.MenuItem(.{ .label = "Quit", .onClick = &close }),
        }),
        capy.Menu(.{ .label = "Edit" }, .{
            capy.MenuItem(.{ .label = "Read", .onClick = &read }),
            capy.MenuItem(.{ .label = "Clear", .onClick = &clear }),
        }),
        capy.Menu(.{ .label = "Help" }, .{
            capy.MenuItem(.{ .label = "About" }),
        }),
    }));

    window.setTitle("zedit");
    window.resize(800, 600);
    window.show();

    capy.runEventLoop();
}

fn close() void {
    std.debug.print("\nCya soon!", .{});
    std.os.exit(0);
}

fn saveBtn(_: *anyopaque) anyerror!void {
    save();
}

fn save() void {
    const file = std.fs.cwd().createFile(
        fileName.get(),
        .{},
    ) catch return;
    defer file.close();

    const bytes_written = file.writeAll(text.get()) catch return;
    _ = bytes_written;
}

// TODO: get rid of limited file size!
fn read() void {
    const file = std.fs.cwd().openFile(
        fileName.get(),
        .{},
    ) catch return;
    defer file.close();

    var buffer: [1024]u8 = undefined;
    file.seekTo(0) catch return;
    const fileSize = file.readAll(&buffer) catch return;

    text.set(buffer[0..fileSize]);
}

fn delete() void {
    _ = std.fs.cwd().deleteFile(fileName.get()) catch return;
}

fn clear() void {
    text.set("");
}
