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

TODO:
- Verify public program commitment

## 2. Brainfuck ISA and Compiler

TODO

## 3. Brainfuck VM in powdr-Rust

TODO
