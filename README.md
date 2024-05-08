# powdr-brainfuck

This repository contains different Brainfuck implementations as
[powdr](https://docs.powdr.org/) VMs.

## 1. Brainfuck VM in powdr-IR

`brainfuck_vm.asm` is a hand-written assembly interpreter that takes the
Brainfuck program (with a zero at the end) and the program inputs as a single
list of numbers encoded as `<program length> <program> <input length> <input>`
and generates a ZK proof of execution, effectively being a zkVM. This is
different from approach (2) which implements an ISA that Brainfuck programs can
be transpiled to.

```console
powdr pil brainfuck_vm.asm -o output -f -i "3,62,44,0,17"
```

This command compiles the interpreter and generates a witness for the program
`>,` with input `[17]`.  Note that the program is given as a list of the ASCII
codes of the program characters.

You can add `--prove-with estark` to the command above to generate a STARK
proof of the execution, or `--prove-with halo2 --field bn254` to generate a
SNARK.

The script `program_formatter.py` helps to format Brainfuck programs as `powdr` inputs:

```console
powdr pil brainfuck_vm.asm -i $(./program_formatter.py hello_world.bf) -o output -f
```

`Hello World!` should be printed during witness generation.


TODO:
- Verify public program commitment

## 2. Brainfuck ISA and Compiler

TODO

## 3. Brainfuck VM in powdr-Rust

The directory `brainfuck-rs` has 3 crates:
- `interpreter`: A Brainfuck interpreter that runs a given program on given
  inputs and returns the outputs that would be printed on `stdout`. The interpreter
  is used by both `host` and `powdr-guest`.
- `host`: The main binary, able to run the interpreter natively as well as make
  ZK proofs using powdr.
- `powdr-guest`: The code to be proven, interfaces with `powdr`'s input API and
  uses the same interpreter code as `host`.

To run just the native interpreter, run:
```console
cargo run -r -- --program ../hello_world.bf -e
```

To run powdr's compilation and RISCV executor only, run:
```console
RUST_LOG=info cargo run -r -- --program ../hello_world.bf -f
```
The `info` option also prints the trace length.

To run powdr's compilation and full witness generation, run:
```console
RUST_LOG=info cargo run -r -- --program ../hello_world.bf -w
```

To run powdr's compilation, full witness and proof generation, run:
```console
cargo run -r -- --program ../hello_world.bf --proof
```
