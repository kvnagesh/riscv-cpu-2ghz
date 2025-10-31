# RISC-V CPU Core - 2 GHz @ 7nm

A high-performance RISC-V CPU core with 10-stage pipeline targeting 2 GHz operation on 7nm process technology.

## Overview

This repository contains synthesizable SystemVerilog RTL code for a RISC-V CPU implementation featuring:

- **10-Stage Deep Pipeline** for high-frequency operation
- **Target Frequency**: 2 GHz
- **Process Technology**: 7nm
- **L1 Cache**: 16KB 
- **L2 Cache**: 64KB
- **Data Path**: NO RESET on flip-flops (for timing optimization)
- **Control Path**: WITH RESET on flip-flops (for proper initialization)

## Pipeline Architecture

The CPU implements a 10-stage pipeline with proper naming conventions:

### Pipeline Stages

1. **IF (Instruction Fetch)**: Fetches instructions from L1 I-cache
2. **ID (Instruction Decode)**: Decodes RISC-V instructions and reads register file
3. **EX1 (Execute Stage 1)**: Address calculation and operand selection
4. **EX2 (Execute Stage 2)**: ALU operation start (first cycle)
5. **EX3 (Execute Stage 3)**: ALU operation continuation (second cycle)
6. **EX4 (Execute Stage 4)**: ALU operation completion (third cycle)
7. **EX5 (Execute Stage 5)**: Result forwarding and bypass network
8. **MEM (Memory Access)**: L1 D-cache access for load/store operations
9. **WB (Write Back)**: Write results to register file
10. **COM (Commit)**: Commit instruction results (in-order commit)

## Design Specifications

### Pipeline Depth Rationale

The 10-stage pipeline is designed to achieve 2 GHz operation at 7nm:

- **Shallow logic depth per stage**: Each stage has minimal combinational logic
- **Register-heavy design**: Maximum use of pipeline registers
- **Multi-cycle ALU**: 3-stage ALU (EX2-EX4) for complex operations
- **Critical path**: < 500ps per stage

### No-Reset Data Path

**Key Design Principle**: All data path flip-flops do NOT have reset inputs.

#### Rationale:
1. **Timing**: Reset logic adds delay to clock-to-Q path
2. **Area**: Reset circuitry increases cell area
3. **Power**: Reset networks consume static and dynamic power
4. **Frequency**: Enables higher Fmax in 7nm technology

#### Implementation:
```systemverilog
// Example: Data path register without reset
always_ff @(posedge clk) begin
    data_reg <= data_next;  // No reset check
end

// Example: Control path register with reset
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        valid_reg <= 1'b0;
    else
        valid_reg <= valid_next;
end
```

### Cache Hierarchy

#### L1 Cache (16KB)
- **Type**: Split I-cache and D-cache
- **Size**: 16KB each
- **Associativity**: 4-way set associative
- **Line Size**: 64 bytes
- **Latency**: 1 cycle hit, integrated into IF/MEM stages

#### L2 Cache (64KB)
- **Type**: Unified instruction and data cache
- **Size**: 64KB
- **Associativity**: 8-way set associative
- **Line Size**: 64 bytes
- **Latency**: 4-6 cycles

## Directory Structure

```
riscv-cpu-2ghz/
├── rtl/
│   ├── riscv_cpu_top.sv          # Top-level CPU module
│   ├── riscv_if_stage.sv         # IF stage
│   ├── riscv_id_stage.sv         # ID stage
│   ├── riscv_ex1_stage.sv        # EX1 stage
│   ├── riscv_ex2_stage.sv        # EX2 stage
│   ├── riscv_ex3_stage.sv        # EX3 stage
│   ├── riscv_ex4_stage.sv        # EX4 stage
│   ├── riscv_ex5_stage.sv        # EX5 stage
│   ├── riscv_mem_stage.sv        # MEM stage
│   ├── riscv_wb_stage.sv         # WB stage
│   ├── riscv_com_stage.sv        # COM stage
│   ├── riscv_alu.sv              # ALU module
│   ├── riscv_regfile.sv          # Register file
│   ├── riscv_l1_cache.sv         # L1 cache (16KB)
│   ├── riscv_l2_cache.sv         # L2 cache (64KB)
│   └── riscv_decoder.sv          # Instruction decoder
├── tb/
│   └── (testbenches)
├── docs/
│   └── (documentation)
└── README.md
```

## Module Descriptions

### Top-Level Module (riscv_cpu_top.sv)

Instantiates all 10 pipeline stages and connects them.

**Features**:
- Clear stage-to-stage interfaces
- Proper naming convention (if_, id_, ex1_, ex2_, etc.)
- Data path registers without reset
- Control path registers with reset

### Pipeline Stage Modules

Each stage follows a consistent interface pattern:

```systemverilog
module riscv_<stage>_stage (
    input  logic        clk,
    // Input from previous stage
    input  logic [31:0] prev_data,
    input  logic        prev_valid,
    // Output to next stage  
    output logic [31:0] curr_data,  // NO RESET
    output logic        curr_valid  // WITH RESET
);
```

### ALU Module (riscv_alu.sv)

Implements RISC-V arithmetic and logic operations:
- ADD/SUB
- AND/OR/XOR
- SLL/SRL/SRA (shifts)
- SLT/SLTU (comparisons)

**Pipeline**: Operates across EX2-EX4 stages for timing closure.

### Register File (riscv_regfile.sv)

- **Registers**: x0-x31 (x0 hardwired to 0)
- **Ports**: 2 read ports, 1 write port
- **Read**: Asynchronous (combinational)
- **Write**: Synchronous at COM stage
- **Forwarding**: Integrated bypass network

### Cache Modules

#### L1 Cache (riscv_l1_cache.sv)
- Integrated into IF and MEM pipeline stages
- Single-cycle latency for hits
- Non-blocking for misses

#### L2 Cache (riscv_l2_cache.sv)
- Multi-cycle access
- Handles L1 cache misses
- Writeback policy

## Synthesis Considerations

### Timing Constraints

```tcl
# Clock definition for 2 GHz
create_clock -period 0.500 [get_ports clk]

# Input/output delays
set_input_delay -clock clk 0.100 [all_inputs]
set_output_delay -clock clk 0.100 [all_outputs]

# Clock uncertainty for 7nm
set_clock_uncertainty 0.050 [get_clocks clk]
```

### Physical Design

- **Placement**: Register-heavy stages require careful placement
- **Clock tree**: Low-skew clock distribution essential at 2 GHz
- **Power**: Dynamic voltage/frequency scaling for power management

## Design Principles

### 1. **Pipeline Balance**
All stages designed for similar logic depth (< 20 FO4 gates).

### 2. **Register Minimization in Data Path**
No reset on data path flops reduces area and improves timing.

### 3. **Forwarding Network**
EX5 stage provides result forwarding to earlier stages.

### 4. **Control Simplicity**
Control signals have reset for correct initialization but minimal gating.

## Usage

### Synthesis

```bash
# Using Synopsys Design Compiler
dc_shell -f scripts/synthesize.tcl

# Using Cadence Genus
genus -f scripts/synthesize.g
```

### Simulation

```bash
# Using VCS
vcs -sverilog -full64 +v2k -timescale=1ns/1ps \
    rtl/*.sv tb/testbench.sv -o simv
./simv

# Using Verilator
verilator --cc --exe --build -Wall \
    rtl/*.sv tb/testbench.cpp
```

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Frequency | 2.0 GHz | Design Goal |
| IPC | 0.85 | Depends on code |
| Area | < 1 mm² | @ 7nm |
| Power | < 500 mW | @ nominal voltage |
| L1 Hit Rate | > 95% | Application dependent |
| L2 Hit Rate | > 90% | Application dependent |

## Implementation Status

- [x] Top-level module with 10-stage pipeline structure
- [ ] IF stage implementation
- [ ] ID stage implementation  
- [ ] EX1-EX5 stage implementations
- [ ] MEM stage implementation
- [ ] WB stage implementation
- [ ] COM stage implementation
- [ ] ALU module
- [ ] Register file
- [ ] L1 cache (16KB)
- [ ] L2 cache (64KB)
- [ ] Forwarding logic
- [ ] Hazard detection
- [ ] Branch prediction

## Contributing

Contributions are welcome! Please ensure:

1. All data path flip-flops have NO reset
2. All control path flip-flops have reset
3. Code follows naming conventions (stage prefixes)
4. Timing-critical paths are minimized

## License

MIT License

## References

- RISC-V ISA Specification v2.2
- "Computer Architecture: A Quantitative Approach" - Hennessy & Patterson
- ARM Cortex-A series pipeline architecture
- Industry 7nm design guidelines

## Contact

For questions or issues, please open a GitHub issue.

---

**Note**: This is a demonstration design for educational and research purposes. Additional verification and physical design work would be required for silicon implementation.
