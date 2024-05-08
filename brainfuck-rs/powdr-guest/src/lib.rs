#![no_std]

extern crate alloc;
use alloc::vec::Vec;
use alloc::string::String;

use powdr_riscv_runtime::{
    input::get_data_serde,
    print
};

#[no_mangle]
pub fn main() {
    let program: Vec<u32> = get_data_serde(1);
    let inputs: Vec<u32> = get_data_serde(2);

    let output = brainfuck_interpreter::run(program, inputs);
    let output = String::from_utf8(output).unwrap();
    print!("{output}");
}
