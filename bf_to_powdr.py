#!/usr/bin/python

import os
import sys


def compile(program):
    loop_stack = []
    loop_counter = 0
    powdr_asm = []
    for instr in program:
        if instr == ">":
            powdr_asm.append("inc_dp;")
        elif instr == "<":
            powdr_asm.append("dec_dp;")
        elif instr == "+":
            powdr_asm.append("inc_cell;")
        elif instr == "-":
            powdr_asm.append("dec_cell;")
        elif instr == ",":
            powdr_asm.append(
                "data <=X= ${ std::prover::Query::Input(std::convert::int(std::prover::eval(in_ptr))) };"
            )
            powdr_asm.append("mstore data;")
            powdr_asm.append("in_ptr <=X= in_ptr + 1;")
        elif instr == ".":
            powdr_asm.append("data <== mload();")
            powdr_asm.append(
                "data <=X= ${ std::prover::Query::Output(1, std::convert::int(std::prover::eval(data))) };"
            )
        elif instr == "[":
            label_true = f"loop_true_{loop_counter}"
            label_false = f"loop_false_{loop_counter}"
            loop_counter += 1
            powdr_asm.append(f"{label_true}:")
            powdr_asm.append("data <== mload();")
            powdr_asm.append(f"branch_if_zero data, {label_false};")
            loop_stack.append((label_true, label_false))
        elif instr == "]":
            (label_true, label_false) = loop_stack.pop()
            powdr_asm.append(f"jump {label_true};")
            powdr_asm.append(f"{label_false}:")

    powdr_asm.append("return;")
    return powdr_asm


def main():
    if len(sys.argv) != 2:
        print("Usage: bf_to_powdr.py <program.bf>")
        sys.exit(1)

    filename = sys.argv[1]
    with open(filename, "r") as f:
        program = f.read()

    powdr_asm = compile(program)
    powdr_asm = "\n".join(powdr_asm)

    main_function = f"function main {{\n{powdr_asm}\n}}"

    asm_file_path = "brainfuck_template.asm"

    with open(asm_file_path, "r") as file:
        asm_content = file.read()

    compiled_asm = asm_content.replace("{{ program }}", main_function)

    program_name = os.path.splitext(filename)[0]
    compiled_file_path = f"{program_name}.asm"
    with open(compiled_file_path, "w") as file:
        file.write(compiled_asm)


if __name__ == "__main__":
    main()
