use std::machines::range::Byte2;
use std::machines::memory::Memory;

machine Brainfuck {
	Byte2 byte2;
	Memory mem(byte2);

  // the program pc
	reg pc[@pc];
  // assignment register used by instruction parameters
	reg X[<=];

	// data pointer
	reg dp;
	// program's input counter
	reg in_ptr;
  // helper data container
  reg data;

	// iszero check for X
	let XIsZero = std::utils::is_zero(X);

  // instructions needed for Brainfuck operations

	instr branch_if_zero X, l: label
  {
    pc' = XIsZero * l + (1 - XIsZero) * (pc + 1)
  }

	instr jump l: label{ pc' = l }

	instr fail { 1 = 0 }

  instr inc_dp { dp' = dp + 1 }
  instr dec_dp { dp' = dp - 1 }

  // helper column
  col witness C;

  instr inc_cell
    link ~> C = mem.mload(dp, STEP)
    link ~> mem.mstore(dp, STEP, C + 1);

  instr dec_cell
    link ~> C = mem.mload(dp, STEP)
    link ~> mem.mstore(dp, STEP, C - 1);

	// memory instructions
	col fixed STEP(i) { i };
	instr mload -> X
		link ~> X = mem.mload(dp, STEP);

	instr mstore X
		link ~> mem.mstore(dp, STEP, X);

  // compiled Brainfuck program

  {{ program }}
}
