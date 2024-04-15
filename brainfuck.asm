use std::memory::Memory;

/// The machine below implements a basic Brainfuck interpreter.
/// It abuses many registers for a clearer understanding of the code,
/// but it can be optimized quite a bit, by for example:
/// - Re-using registers or moving them to memory
/// - Reading the code and inputs from the prover to memory initially
/// - Re-writing some routines to use fewer rows

/// Soundness considerations:
/// - The opcodes are currently unconstrained, meaning the prover can provide whatever they want.
///	  To fix this, a public commitment to the program needs to be passed and verified in the machine below.

/// Program and input encoding:
/// The prover input is a list of numbers encoded as follows
/// <program_length> <program> <input>
/// where <program> needs to end with a 0
/// Example:
/// [2, 44, 0, 1]
/// This program has length 2, where the program is [44, 0] (read, finish)
/// The input list is [1]

machine Brainfuck {
	Memory mem;

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

	// General purpose registers
	reg ret_addr;
	reg A;

	instr jump l: label -> Y { pc' = l, Y = pc + 1}
	instr jump_dyn X -> Y { pc' = X, Y = pc + 1}
	instr branch_if_zero X, l: label { pc' = XIsZero * l + (1 - XIsZero) * (pc + 1) }
	instr fail { 1 = 0 }

	// ============== memory instructions ==============
	col fixed STEP(i) { i };
	instr mload X -> Y ~ mem.mload X, STEP -> Y;
	instr mstore X, Y -> ~ mem.mstore X, STEP, Y ->;

	// ============== iszero check for X =======================
	let XIsZero = std::utils::is_zero(X);

	// === brainfuck interpreter ==========
	function main {
		ret_addr <== jump(__runtime_start);

		exit:
			return;

		run_op:
			// TODO loops

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
			// unknown op
			fail;

		routine_move_right:
			// This is needed because powdr's memory witgen requires 4-aligned addresses.
			// TODO replace by `dp <=X= dp + 1;` when PR 1271 is merged.
			dp <=X= dp + 4;
			A <== jump(end_run_op);

		routine_move_left:
			// This is needed because powdr's memory witgen requires 4-aligned addresses.
			// TODO replace by `dp <=X= dp + 1;` when PR 1271 is merged.
			dp <=X= dp - 4;
			A <== jump(end_run_op);

		routine_inc:
			A <== mload(dp);
			mstore dp, A + 1;
			A <== jump(end_run_op);

		routine_dec:
			A <== mload(dp);
			mstore dp, A - 1;
			A <== jump(end_run_op);

		routine_read:
			A <=X= ${ std::prover::Query::Input(std::convert::int(std::prover::eval(in_ptr))) };
			in_ptr <=X= in_ptr + 1;
			mstore dp, A;
			A <== jump(end_run_op);

		routine_write:
			A <== mload(dp);
			A <=X= ${ std::prover::Query::PrintChar(std::convert::int(std::prover::eval(dp))) };
			A <== jump(end_run_op);

		end_run_op:
			A <== jump_dyn(ret_addr);

		__runtime_start:
			A <=X= ${ std::prover::Query::Input(0) };
			in_ptr <=X= A + 1;
			b_pc <=X= 1;
			dp <=X= 40;

		interpreter_loop:
			// TODO this can be optimized by reading the whole program at once to memory
			// TODO we should also hash the program and expose as public
			op <=X= ${ std::prover::Query::Input(std::convert::int(std::prover::eval(b_pc))) };

			branch_if_zero op, exit;

			b_pc <=X= b_pc + 1;
			ret_addr <== jump(run_op);

			A <== jump(interpreter_loop);
	}
}
