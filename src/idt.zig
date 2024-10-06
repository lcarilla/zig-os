const std = @import("std");
const log = std.log.scoped(.x86_idt);
const builtin = @import("builtin");
const panic = @import("../../panic.zig").panic;
const assembly = @import("./asm.zig");

/// The structure that contains all the information that each IDT entry needs.
pub const IdtEntry = packed struct {
    /// The lower 16 bits of the base address of the interrupt handler offset.
    base_low: u16,

    /// The code segment in the GDT which the handlers will be held.
    selector: u16,

    /// Must be zero, unused.
    zero: u8,

    /// The IDT gate type.
    gate_type: u4,

    /// Must be 0 for interrupt and trap gates.
    storage_segment: u1,

    /// The minimum ring level that the calling code must have to run the handler. So user code may not be able to run some interrupts.
    privilege: u2,

    /// Whether the IDT entry is present.
    present: u1,

    /// The upper 16 bits of the base address of the interrupt handler offset.
    base_high: u16,
};

/// The IDT pointer structure that contains the pointer to the beginning of the IDT and the number
/// of the table (minus 1). Used to load the IST with LIDT instruction.
pub const IdtPtr = packed struct {
    /// The total size of the IDT (minus 1) in bytes.
    limit: u16,

    /// The base address where the IDT is located.
    base: u32,
};

/// The total size of all the IDT entries (minus 1).
const TABLE_SIZE: u16 = @sizeOf(IdtEntry) * NUMBER_OF_ENTRIES - 1;

/// The total number of entries the IDT can have (2^8).
pub const NUMBER_OF_ENTRIES: u16 = 256;

var idt_ptr: IdtPtr = IdtPtr{
    .limit = TABLE_SIZE,
    .base = 0,
};

var idt_entries: [NUMBER_OF_ENTRIES]IdtEntry = [_]IdtEntry{IdtEntry{
    .base_low = 0,
    .selector = 0,
    .zero = 0,
    .gate_type = 0,
    .storage_segment = 0,
    .privilege = 0,
    .present = 0,
    .base_high = 0,
}} ** NUMBER_OF_ENTRIES;

pub fn addEntry(index: u8, base: u32, selector: u16, gate_type: u4, privilege: u2) *IdtEntry {
    idt_entries[index] = IdtEntry{
        .base_low = @intCast(base),
        .selector = selector,
        .zero = 0,
        .gate_type = gate_type,
        .storage_segment = 0,
        .privilege = privilege,
        // Creating a new entry, so is now present.
        .present = 1,
        .base_high = @intCast(base >> 16),
    };

    return &idt_entries[index];
}

pub fn init() void {
    idt_ptr.base = @intFromPtr(&idt_entries);

    assembly.lidt(&idt_ptr);
}
