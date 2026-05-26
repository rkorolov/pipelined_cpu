Implementation of five stage Pipelined CPU. 

Stages:
* Instruction Fetch (instruction_fetch.sv)
    -> Uses the current program counter (PC) to fetch the next instruction from instruction memory
    -> Designated +4 adder for computing PC+4 (word aligned instructions)
    -> If we are branching, the next instruction will be the one at branch address (PC + 4 * Branch offset) instead of the instruction that immediately follows (PC+4)
* Instruction Decode (instruction_decode.sv)
    -> Using the current instruction & previously set flags, generates control signals based off of LEGv8 (control.sv) 
    -> Computes all operands
        - Bit slices Rd, Rm, Rn from the Instruction (operand_fetch.sv)
        - Computes sign extensions for branch offsets (unconditional & conditional branches) & byte offsets (memory access)
        - Computes a zero extension for ALU immediates
    -> (NEW) In contrast to the unpipelined version, this pipelined implementation computes branch addresses in the ID stage. This is to reduce branch
    penalities in the case we were incorrect about branching (from 3 cycles (IF_ID, ID_EX, EX_MEM) to 1 cycle (IF_ID)).
* Execute (execute.sv)
    -> Computes an ALU Result
        - Control signals to determine which ALU operation type to compute (ALUOp) & which operands to use (ALUSrc)
        - ex: Da and Db operations, computing effective memory addresses.
    -> Generates flags
        - *Flags are set if enabled by flag write (FlagWrite)
* Memory Access (cpu.sv 247-255)
    -> Reads or writes to memory depending on the memory read (MemRead) & memory write (MemWrite)
* Writeback (cpu.sv 257-272)
    -> Writes data back into register file
        - *data will only actually be written depending on register write enable
        - source of data depends memory to register control signal: either we're writing the next instruction address (PC+4) in BL cases, the data we read from memory, or the result of the ALU

Pipelining Notes:
* Pipeline Registers
  -> With the addition of pipeline registers between each stage, stages can now communicate with each across clock cycles. At the positive edge of a clock cycle,
  data is transferred between each pipeline register (if_id, id_ex, ex_mem, & mem_wb).
* Read/Write Conflicts
  -> To deal with read write conflicts, I chose to write on the negative edge of the clock cycle (i.e the registers in the register file update on the neg edge
  as well as the flag registers). An alternative approach is reading on the negative edge and writing on the positive edge, but my way was only a two-line update.
* Data Forwarding
  -> With pipelining comes the issue of needed data before it's written in the previous instruction. Instead of stalling, it's possible to use data when it's ready instead of when it's written through
  the use of forwarding values from the previous cycle's registers. So when we need data in the execute stage, we can look ahead at the stored values in the ex_mem & the mem_wb registers.
* Data Hazards
  -> There are some cases where the data isn't ready and thus cannot be forwarded, so we need to stall. This is the case for load use hazards, where we want to use the data that is being
  loaded in from memory in the very next instruction. Additionally, for the CBZ instruction a stall is needed since CBZ directly checks the second register input value -> which needs to be
  written into the register first. 
* Control Hazards
  -> Another hazard has to do with conditional branches, where we need to resolve the condition to decide if we want to branch or not. One solution is to have a delay slot immediately after
  each branch (this is also a valid solution for load instructions), but I implemented a dynamic 2-bit branch predictor. This predictor changes its prediction (either Always Taken or Not Taken) after
  being incorrect twice in a row. I chose to have the reset state be Always Taken to avoid having to flush twice on two branches taken in a row - which fit better with my benchmarks.
  When a branch is taken, the immediately following instruction (PC+4) that was fetched is flushed, and execution continues from the branch target — giving a 1-cycle branch penalty.
  of 1. 

General Notes:
* Separate modules for instruction & data memory to avoid contention for the same resource
* Data memory is double word aligned & instruction memory is word aligned
* Gate level logic is used everywhere, except for RTL in control units.
