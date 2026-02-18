# NN_RISC-V

RISC-V 5-stage pipeline core with an integrated NN (matrix-multiply) accelerator.

This project was developed as part of the Kwangwoon University AI Semiconductor Design Project.

## Top
- `RISC_V.v` is the top module.
- Pipeline: IF / ID / EXE / MEM / WB with hazard interlock and data forwarding.
- Custom NN instruction opcode: `OP_NN = 7'b0001011` (see `ID/Control_Unit.v`).

## Memory Interfaces
`RISC_V.v` exposes five BRAM interfaces for FPGA:
- Instruction RAM: `inst_ram_*`
- Data RAM: `mem_ram_*`
- Control RAM: `ctrl_ram_*` (start signal + instruction count)
- Input RAM (NN input): `input_ram_*`
- Weight RAM (NN weights): `weight_ram_*`

Notes from RTL:
- Instruction address uses word addressing via `PC[7:2]` (see `IF/IF_top.v`).
- When NN finishes, `dnn_output` is written through the data RAM path (see `RISC_V.v`).

## NN Core
`RTL/RISC-V/nn_core/nn_core.v`
- FSM states: IDLE -> RUN0 -> RUN1 -> RUN2 -> DONE.
- RUN0: `mac_fc1` accumulates 16 neurons with ReLU into a 144-bit vector (16 x 9-bit).
- RUN1: `mac_fc2` accumulates 10 neurons with ReLU into a 200-bit vector (10 x 20-bit).
- RUN2: `compare` selects the max index (0-9). Output is `result_0 = {28'd0, max_index}`.
- Input/weight RAM addresses increment sequentially during RUN0/RUN1.

Files:
- `nn_core/mac_fc1.v`
- `nn_core/mac_fc2.v`
- `nn_core/compare.v`

## Pipeline Blocks
- IF: `IF/IF_top.v` (PC + branch mux)
- ID: `ID/ID_top.v`, `Control_Unit.v`, `Register_File.v`, `Extension_Unit.v`
- EXE: `EXE/EXE_top.v`, `ALU.v`, `branch_and.v`
- MEM/WB: `MEM/MEM_top.v`, `WB/WB_top.v`
- Hazards: `interlock.v` (load-use + NN stall), `data_forwarding.v`

## Custom NN Instruction Behavior
- Decoded in `Control_Unit.v` as `OP_NN`.
- Asserts `dnn_start` into the pipeline.
- Interlock stalls the pipeline while NN is running, then releases on `dnn_done`.

## Directory Structure
  - `IF/`, `ID/`, `EXE/`, `MEM/`, `WB/` pipeline stages
  - `nn_core/` NN accelerator blocks