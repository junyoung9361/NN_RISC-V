# FC_RISC-V RTL

RISC-V 5-stage pipeline core with an integrated NN (matrix-multiply) accelerator.

This project was developed as part of the Kwangwoon University AI Semiconductor Design Project.

## Top-Level
- `RISC_V.v` is the top module.
- Pipeline: IF / ID / EXE / MEM / WB with hazard interlock and data forwarding.
- Custom NN instruction opcode: `OP_NN = 7'b0001011` (see `RTL/RISC-V/ID/Control_Unit.v`).

## Memory Interfaces (Top-Level Ports)
`RISC_V.v` exposes five BRAM-style interfaces:
- Instruction RAM: `inst_ram_*`
- Data RAM: `mem_ram_*`
- Control RAM: `ctrl_ram_*` (start signal + instruction count)
- Input RAM (NN input): `input_ram_*`
- Weight RAM (NN weights): `weight_ram_*`

Notes from RTL:
- Instruction address uses word addressing via `PC[7:2]` (see `RTL/RISC-V/IF/IF_top.v`).
- When NN finishes, `dnn_output` is written through the data RAM path (see `RTL/RISC-V/RISC_V.v`).

## NN Core
`RTL/RISC-V/nn_core/nn_core.v`
- FSM states: IDLE -> RUN0 -> RUN1 -> RUN2 -> DONE.
- RUN0: `mac_fc1` accumulates 16 neurons with ReLU into a 144-bit vector (16 x 9-bit).
- RUN1: `mac_fc2` accumulates 10 neurons with ReLU into a 200-bit vector (10 x 20-bit).
- RUN2: `compare` selects the max index (0-9). Output is `result_0 = {28'd0, max_index}`.
- Input/weight RAM addresses increment sequentially during RUN0/RUN1.

Files:
- `RTL/RISC-V/nn_core/mac_fc1.v`
- `RTL/RISC-V/nn_core/mac_fc2.v`
- `RTL/RISC-V/nn_core/compare.v`

## Pipeline Blocks
- IF: `RTL/RISC-V/IF/IF_top.v` (PC + branch mux)
- ID: `RTL/RISC-V/ID/ID_top.v`, `Control_Unit.v`, `Register_File.v`, `Extension_Unit.v`
- EXE: `RTL/RISC-V/EXE/EXE_top.v`, `ALU.v`, `branch_and.v`
- MEM/WB: `RTL/RISC-V/MEM/MEM_top.v`, `RTL/RISC-V/WB/WB_top.v`
- Hazards: `RTL/RISC-V/interlock.v` (load-use + NN stall), `RTL/RISC-V/data_forwarding.v`

## Custom NN Instruction Behavior
- Decoded in `Control_Unit.v` as `OP_NN`.
- Asserts `dnn_start` into the pipeline.
- Interlock stalls the pipeline while NN is running, then releases on `dnn_done`.

## Parameters (Top-Level)
See `RTL/RISC-V/RISC_V.v` for parameter defaults:
- `INST_WIDTH`, `MEM_DWIDTH`, `MEM_AWIDTH`
- Instruction BRAM depth (`MEM0_MEM_DEPTH`)
- Data BRAM depth (`MEM1_MEM_DEPTH`)
- Control BRAM depth (`MEM_DEPTH`)
- Input/Weight BRAM depths (`MEM3_MEM_DEPTH`, `MEM4_MEM_DEPTH`)
- `DNN_WIDTH`

## Directory Structure
- `RTL/RISC-V/` RISC-V core + NN accelerator
  - `IF/`, `ID/`, `EXE/`, `MEM/`, `WB/` pipeline stages
  - `nn_core/` NN accelerator blocks

## Quick Integration Checklist
- Hook BRAMs to the five memory ports.
- Provide reset, clock, and instruction memory contents.
- Use the NN opcode (`0x0B` in [6:0]) to trigger acceleration.
