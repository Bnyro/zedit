const std = @import("std");
const capy = @import("capy");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var alloc = arena.allocator();

var text = capy.Atom([]const u8).of("Hello World!");
var fileName = capy.Atom([]const u8).of("foo.txt");
var monospace = capy.Atom(bool).of(false);

pub fn main() !void {
    defer _ = arena.deinit();

    try capy.backend.init();
    var window = try capy.Window.init();

    const margin = capy.Rectangle.init(10, 10, 10, 10);
    try window.set(capy.Column(.{ .spacing = 0 }, .{
        capy.Expanded(capy.Margin(margin, capy.TextArea(.{}).bind("text", &text).bind("monospace", &monospace))),
        capy.Margin(margin, capy.Align(.{}, capy.Row(.{}, .{ capy.CheckBox(.{ .label = "Monospaced" }).bind("checked", &monospace), capy.TextField(.{ .text = "foo.txt" }).bind("text", &fileName), capy.Button(.{ .label = "Save", .onclick = &saveBtn }) }))),
    }));

    setup_initial_input();

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

fn setup_initial_input() void {
    const args = std.process.argsAlloc(alloc) catch return;
    defer std.process.argsFree(alloc, args);
    if (args.len <= 1) return;

    const fna = std.fmt.allocPrint(alloc, "{s}", .{args[1]}) catch return;
    fileName.set(fna);

    read();
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

fn read() void {
    const file = std.fs.cwd().openFile(
        fileName.get(),
        .{},
    ) catch return;

    defer file.close();
    const buffer = file.readToEndAlloc(alloc, std.math.maxInt(usize)) catch return;
    text.set(buffer);
}

fn delete() void {
    _ = std.fs.cwd().deleteFile(fileName.get()) catch return;
}

fn clear() void {
    text.set("");
}
