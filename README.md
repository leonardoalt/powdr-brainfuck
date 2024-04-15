# powdr-brainfuck

This repository contains different Brainfuck implementations as
[powdr](https://docs.powdr.org/) VMs.

## Assembly Interpreter

`brainfuck.asm` is a hand-written assembly interpreter that takes the Brainfuck
program (with a zero at the end) and the program inputs as a single list of
numbers encoded as `<program length> <program> <input>`.

```console
powdr pil brainfuck.asm -o output -f -i "3,62,44,0,17"
```

This command compiles the interpreter and generates a witness for the program
`>,` with input `[17]`.  Note that the program is given as a list of the ASCII
codes of the program characters.

You can add `--prove-with estark` to the command above to generate a STARK
proof of the execution, or `--prove-with halo2 --field bn254` to generate a
SNARK.

TODO:
- Support brainfuck loops
- Verify public program commitment

## Brainfuck VM in powdr-IR

TODO

## Brainfuck VM in powdr-Rust

TODO
