#![no_main]
#![no_std]

extern crate alloc;
use alloc::string::String;
use alloc::vec::Vec;
use alloc::collections::VecDeque;

use powdr_riscv_runtime::{io::read, print};

#[no_mangle]
pub fn main() {
    let program: Vec<u32> = read(1);
    let inputs: VecDeque<i64> = read(2);

    let (_, output) = brainfuck_interpreter::run(program, inputs);
    let output = String::from_utf8(output).unwrap();
    print!("{output}");
}
