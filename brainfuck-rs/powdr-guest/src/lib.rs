#![no_std]

extern crate alloc;
use alloc::string::String;
use alloc::vec::Vec;

use powdr_riscv_runtime::{io::read, print};

#[no_mangle]
pub fn main() {
    let program: Vec<u32> = read(1);
    let inputs: Vec<u32> = read(2);

    let output = brainfuck_interpreter::run(program, inputs);
    let output = String::from_utf8(output).unwrap();
    print!("{output}");
}
