const idt = @import("idt.zig");

pub fn initKeyboard() void {
    idt.addEntry(0x21, base: u32, selector: u16, gate_type: u4, privilege: u2);
    idt.init();
}
