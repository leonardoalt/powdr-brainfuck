/// The machine below implements a basic Brainfuck interpreter.
/// It abuses many registers for a clearer understanding of the code,
/// but it can be optimized quite a bit, by for example:
/// - Re-using registers or moving them to memory
/// - Re-writing some routines to use fewer rows

/// Soundness considerations:
/// - The opcodes are currently unconstrained, meaning the prover can provide whatever they want.
///   To fix this, a public commitment to the program needs to be passed and verified in the machine below.

/// Program and input/output encoding:
/// The prover input is a list of numbers encoded as follows
/// <program_length> <program> <input_length> <input>
/// where <program> needs to end with a 0
/// Example:
/// [2, 44, 0, 1, 97]
/// This program has length 2, where the program is [44, 0] (read, finish)
/// and the input list is [97].
/// The `.` (print) instruction treats its input as the ASCII code of a character,
/// and prints that character.

use std::machines::range::Byte2;
use std::machines::memory::Memory;

machine Brainfuck {
	Byte2 byte2;
	Memory mem(byte2);

	reg pc[@pc];
	reg X[<=];
	reg Y[<=];
	reg Z[<=];

	// The pc of the given Brainfuck program
	reg b_pc;
	// The current operator
	reg op;
	// Data pointer
	reg dp;
	// program's input counter
	reg in_ptr;
	// the stack of loop addresses
	reg loop_sp;

	// General purpose registers
	reg ret_addr;
	reg A;
	reg CNT;
	reg tmp1;

	instr jump l: label -> Y { pc' = l, Y = pc + 1}
	instr jump_dyn X -> Y { pc' = X, Y = pc + 1}
	instr branch_if_zero X, l: label { pc' = XIsZero * l + (1 - XIsZero) * (pc + 1) }
	instr fail { 1 = 0 }

	// ============== memory instructions ==============
	col fixed STEP(i) { i };
	instr mload X -> Y
		link ~> Y = mem.mload(X, STEP);

	instr mstore X, Y
		link ~> mem.mstore(X, STEP, Y);

	// ============== iszero check for X =======================
	let XIsZero = std::utils::is_zero(X);

	// === Brainfuck interpreter ==========
	function main {
		// calls the main entry point of the program
		ret_addr <== jump(__runtime_start);

		// exits entire program
		exit:
			return;

		// ==== helper routine to read the program and inputs from prover into memory
		read_program_and_input:
			// read the length of the program
			A <=X= ${ std::prelude::Query::Input(0) };
			CNT <=X= 0;
		read_program_loop:
			branch_if_zero A - CNT, end_read_program;
			mstore CNT + 0 /*PROGRAM_START*/, ${ std::prelude::Query::Input(std::convert::int(std::prover::eval(CNT)) + 1) };
			CNT <=X= CNT + 1;
			tmp1 <== jump(read_program_loop);
		end_read_program:
		read_input:
			CNT <=X= 0;
			// read input length
			in_ptr <=X= ${ std::prelude::Query::Input(std::convert::int(std::prover::eval(A)) + 1) };
		read_input_loop:
			branch_if_zero in_ptr - CNT, end_read_input;
			mstore CNT + 10000 /*INPUT_START*/, ${ std::prelude::Query::Input(std::convert::int(std::prover::eval(CNT) + std::prover::eval(A)) + 2) };
			CNT <=X= CNT + 1;
			tmp1 <== jump(read_input_loop);
		end_read_input:
			mstore CNT + 10000 /*INPUT_START*/, -1;
			A <== jump_dyn(ret_addr);
		// ==== end of helper routine

		// ==== helper routine that decodes and runs an opcode
		run_op:
			// '>' is 62
			branch_if_zero op - 62, routine_move_right;
			// '<' is 60
			branch_if_zero op - 60, routine_move_left;
			// '+' is 43
			branch_if_zero op - 43, routine_inc;
			// '-' is 45
			branch_if_zero op - 45, routine_dec;
			// ',' is 44
			branch_if_zero op - 44, routine_read;
			// '.' is 46
			branch_if_zero op - 46, routine_write;
			// '[' is 91
			branch_if_zero op - 91, routine_loop_start;
			// ']' is 93
			branch_if_zero op - 93, routine_loop_end;
			// unknown op
			fail;

		// ==== helper routine for `[`
		routine_loop_start:
			A <== mload(dp);
			// If the current cell is zero, find the matching ']' and set b_op
			// to after that.
			branch_if_zero A, loop_exit;
		loop_enter:
			// We're entering the loop: save the loop start pc.
			loop_sp <=X= loop_sp + 1;
			mstore loop_sp, b_pc;
			A <== jump(end_run_op);
		loop_exit:
			// Scope counter, needed to exit nested loops.
			CNT <=X= 1;
			A <=X= b_pc;
		search_for_loop_end:
			A <=X= A + 1;
			op <== mload(A);
			branch_if_zero op - 91, found_loop_enter;
			branch_if_zero op - 93, found_loop_exit;
			tmp1 <== jump(search_for_loop_end);
		found_loop_enter:
			// If we see a nested opening loop we increase the counter.
			CNT <=X= CNT + 1;
			tmp1 <== jump(search_for_loop_end);
		found_loop_exit:
			// If we see a closing loop and the counter is zero, we found the
			// matching loop.
			CNT <=X= CNT - 1;
			branch_if_zero CNT, exit_loop;
			tmp1 <== jump(search_for_loop_end);
		exit_loop:
			// We set the pc to the closing loop because the main interpreter
			// loop always increments it by 1 by default.
			b_pc <=X= A;
			A <== jump(end_run_op);
		// ==== end of `[` helper routine

		// ==== helper routine for `]`
		routine_loop_end:
			// When we see a `]`, we need to jump back to the start of the
			// loop.
			// We set `b_pc` to before the start of the loop because the
			// main interpreter loop always increments it by 1 by default.
			b_pc <== mload(loop_sp);
			b_pc <=X= b_pc - 1;
			loop_sp <=X= loop_sp - 1;
			A <== jump(end_run_op);
		// ==== end of `]` helper routine

		// ==== helper routine for `>`
		routine_move_right:
			dp <=X= dp + 1;
			A <== jump(end_run_op);
		// ==== end of `>` helper routine

		// ==== helper routine for `<`
		routine_move_left:
			dp <=X= dp - 1;
			A <== jump(end_run_op);
		// ==== end of `<` helper routine

		// ==== helper routine for `+`
		routine_inc:
			A <== mload(dp);
			mstore dp, A + 1;
			A <== jump(end_run_op);
		// ==== end of `+` helper routine

		// ==== helper routine for `-`
		routine_dec:
			A <== mload(dp);
			mstore dp, A - 1;
			A <== jump(end_run_op);
		// ==== end of `-` helper routine

		// ==== helper routine for `,`
		routine_read:
			A <== mload(in_ptr);
      in_ptr <=X= in_ptr + 1;
			mstore dp, A;
			A <== jump(end_run_op);
		// ==== end of `,` helper routine

		// ==== helper routine for `.`
		routine_write:
			A <== mload(dp);
			A <=X= ${ std::prelude::Query::Output(1, std::convert::int(std::prover::eval(A))) };
			A <== jump(end_run_op);
		// ==== end of `.` helper routine

		end_run_op:
			A <== jump_dyn(ret_addr);
		// ==== end of opcode helper routine

		// ==== program entry point
		__runtime_start:
			ret_addr <== jump(read_program_and_input);

			// Arbitrary sizes for the memory regions
			// The main part is memory (dp)
			b_pc <=X= 0 /*PROGRAM_START*/;
			in_ptr <=X= 10000 /*INPUT_START*/;
			loop_sp <=X= 20000 /*LOOP_STACK_START*/;
			dp <=X= 30000 /*MEM_START*/;

		// ==== main interpreter loop
		interpreter_loop:
			// TODO we should also hash the program and expose as public
			op <== mload(b_pc);

			branch_if_zero op, exit;

			ret_addr <== jump(run_op);
			b_pc <=X= b_pc + 1;

			A <== jump(interpreter_loop);
		// ==== end of main interpreter loop
	}
}
