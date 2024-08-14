#!/usr/bin/python

import sys


def main():
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print("Usage: program_formatter.py <program.bf> [input.in]")
        sys.exit(1)
    filename = sys.argv[1]
    with open(filename, "r") as f:
        program = f.read()

    formatted_program = [
        ord(c) for c in program if c in [">", "<", "+", "-", ".", ",", "[", "]"]
    ]
    formatted_program = [len(formatted_program) + 1] + formatted_program + [0]
    joined_program = ", ".join(map(str, formatted_program)).replace(" ", "")

    input_data = []
    if len(sys.argv) == 3:
        input_filename = sys.argv[2]
        with open(input_filename, "r") as f:
            input_data = f.read()

        input_data = input_data.strip("\n").split(",")
        input_data = [int(c) for c in input_data]

    input_data = [len(input_data)] + input_data
    joined_input = ", ".join(map(str, input_data)).replace(" ", "")
    joined_program += "," + joined_input

    print(joined_program)


if __name__ == "__main__":
    main()
