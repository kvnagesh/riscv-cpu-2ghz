# RISC-V CPU Core - 2 GHz @ 7nm - RV64I Support

A high-performance RISC-V CPU core with 10-stage pipeline targeting 2 GHz operation on 7nm process technology.

## Overview

This repository contains synthesizable SystemVerilog RTL code for a **RV64I** (64-bit) RISC-V CPU implementation featuring:

- **10-Stage Deep Pipeline** for high-frequency operation
- **RV64I ISA**: Full 64-bit RISC-V Integer Instruction Set (50+ instructions)
- **64-bit Data Path**: Complete 64-bit registers, ALU, and memory interface
- **Target Frequency**: 2 GHz
- **Process Technology**: 7nm
- **L1 Caches**: 16KB (4-way set associative, split I/D)
- **L2 Cache**: 64KB (8-way set associative, unified)
- **Data Path**: NO RESET on flip-flops (for timing optimization)
- **Control Path**: WITH RESET on flip-flops (for proper initialization)

## RV64I Instruction Set Support

The CPU implements the complete RV64I base integer instruction set:

### Integer Computational Instructions (64-bit)
- **Arithmetic**: ADD, SUB, ADDI
- **Arithmetic (32-bit)**: ADDW, ADDIW, SUBW
- **Logical**: AND, OR, XOR, ANDI, ORI, XORI
- **Shift (64-bit)**: SLL, SRL, SRA, SLLI, SRLI, SRAI
- **Shift (32-bit)**: SLLW, SRLW, SRAW, SLLIW, SRLIW, SRAIW
- **Comparison**: SLT, SLTU, SLTI, SLTIU
- **Upper Immediate**: LUI, AUIPC

### Control Transfer Instructions
- **Unconditional Jumps**: JAL, JALR
- **Conditional Branches**: BEQ, BNE, BLT, BGE, BLTU, BGEU

### Load Instructions (with sign/zero extension)
- **Sign-Extended**: LB, LH, LW, LD
- **Zero-Extended**: LBU, LHU, LWU

### Store Instructions
- **Byte/Halfword/Word/Doubleword**: SB, SH, SW, SD

### System Instructions
- **Memory Ordering**: FENCE
- **Environment**: ECALL, EBREAK

## Pipeline Architecture

The CPU implements a 10-stage pipeline with proper naming conventions:

### Pipeline Stages

1. **IF** (Instruction Fetch): Fetches 32-bit instructions, manages 64-bit PC
2. **ID** (Instruction Decode): Decodes all RV64I instructions, generates 64-bit immediates
3. **EX1** (Execute 1): Register file read (64-bit registers x0-x31)
4. **EX2** (Execute 2): 64-bit ALU operations, W-suffix instruction support
5. **EX3** (Execute 3): ALU pipeline stage 2
6. **EX4** (Execute 4): ALU pipeline stage 3
7. **EX5** (Execute 5): Final ALU stage before memory
8. **MEM** (Memory Access): 64-bit load/store with proper sign/zero extension
9. **WB** (Write Back): 64-bit write-back to register file
10. **COM** (Commit): Final commit point

### Critical Path

Each stage is designed for < 500ps critical path to achieve 2 GHz operation at 7nm:
- Minimal logic depth per stage
- Balanced pipeline stages
- Optimized for high-frequency synthesis

## Architecture Highlights

### 64-bit Data Path
- All data registers extended to 64-bit
- 32 x 64-bit general-purpose registers (x0-x31)
- x0 hardwired to zero
- 64-bit ALU with full RV64I operation support
- 64-bit memory interface

### W-Suffix Instructions
- Special support for 32-bit operations (ADDW, SUBW, SLLW, SRLW, SRAW)
- Results sign-extended to 64-bit
- Proper 32-bit arithmetic semantics

### Memory System
- L1 I-Cache: 16KB, 4-way set associative
- L1 D-Cache: 16KB, 4-way set associative
- L2 Cache: 64KB, 8-way set associative, unified
- Support for byte, halfword, word, and doubleword access
- Proper alignment and sign/zero extension

## Design Philosophy

### Timing Optimization
- **Data path registers**: NO RESET for optimal timing
- **Control path registers**: WITH RESET for proper initialization
- Deep pipeline for frequency scaling
- Minimized combinational logic per stage

### Naming Conventions
- Stage prefixes: `if_`, `id_`, `ex1_`, `ex2_`, `ex3_`, `ex4_`, `ex5_`, `mem_`, `wb_`, `com_`
- Clear signal naming for maintainability
- Consistent coding style throughout

## Files Structure

```
rtl/
├── riscv_cpu_top.sv      # Top-level CPU module
├── riscv_if_stage.sv     # Instruction Fetch (64-bit PC)
├── riscv_id_stage.sv     # Instruction Decode (RV64I full decoder)
├── riscv_ex1_stage.sv    # Execute Stage 1 (Register Read)
├── riscv_ex2_stage.sv    # Execute Stage 2 (ALU)
├── riscv_ex3_stage.sv    # Execute Stage 3
├── riscv_ex4_stage.sv    # Execute Stage 4
├── riscv_ex5_stage.sv    # Execute Stage 5
├── riscv_mem_stage.sv    # Memory Access (64-bit loads/stores)
├── riscv_wb_stage.sv     # Write Back (64-bit)
├── riscv_com_stage.sv    # Commit Stage
├── riscv_alu.sv          # 64-bit ALU with RV64I operations
├── riscv_regfile.sv      # 32 x 64-bit Register File
├── riscv_l1_cache.sv     # L1 Cache (16KB)
└── riscv_l2_cache.sv     # L2 Cache (64KB)
```

## Implementation Notes

### RV64I Compliance
- Implements full RV64I base integer instruction set
- 64-bit addressing (though instructions remain 32-bit)
- Proper immediate sign-extension to 64-bit
- W-suffix instructions for 32-bit arithmetic

### Production Ready
- Clean, synthesizable SystemVerilog
- No latches, no combinational loops
- Proper reset strategy (control path only)
- Timing-optimized for 2 GHz @ 7nm

## License

MIT License - See individual files for full license text.

Copyright (c) 2025 Nagesh Vishnumurthy
