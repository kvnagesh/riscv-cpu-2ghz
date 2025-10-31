//==============================================================================
// Copyright (c) 2025 Nagesh Vishnumurthy
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//==============================================================================

//==============================================================================
// File: riscv_cpu_top.sv
// Description: RISC-V CPU Top-Level Module with 10-Stage Pipeline
//              Targeting 2 GHz @ 7nm Process
// Pipeline Stages:
//   1. IF    - Instruction Fetch
//   2. ID    - Instruction Decode
//   3. EX1   - Execute Stage 1 (Address Calculation)
//   4. EX2   - Execute Stage 2 (ALU Operation Start)
//   5. EX3   - Execute Stage 3 (ALU Operation Continue)
//   6. EX4   - Execute Stage 4 (ALU Operation Complete)
//   7. EX5   - Execute Stage 5 (Result Forwarding)
//   8. MEM   - Memory Access
//   9. WB    - Write Back
//   10. COM  - Commit
// Notes:
//   - All data path flops have NO reset (for high-frequency operation)
//   - Only control path flops have reset
//   - L1 Cache: 16KB, L2 Cache: 64KB
//==============================================================================

module riscv_cpu_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // Instruction Memory Interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    input  logic        imem_valid,
    
    // Data Memory Interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic [3:0]  dmem_be,
    input  logic [31:0] dmem_rdata,
    input  logic        dmem_valid
);

    //==========================================================================
    // Pipeline Stage Registers - NO RESET on data path
    //==========================================================================
    
    // IF Stage Registers
    logic [31:0] if_pc;              // No reset - data path
    logic [31:0] if_inst;            // No reset - data path
    
    // ID Stage Registers
    logic [31:0] id_pc;              // No reset - data path
    logic [31:0] id_inst;            // No reset - data path
    logic [4:0]  id_rs1_addr;        // No reset - data path
    logic [4:0]  id_rs2_addr;        // No reset - data path
    logic [4:0]  id_rd_addr;         // No reset - data path
    logic [31:0] id_imm;             // No reset - data path
    
    // EX1 Stage Registers
    logic [31:0] ex1_pc;             // No reset - data path
    logic [31:0] ex1_rs1_data;       // No reset - data path
    logic [31:0] ex1_rs2_data;       // No reset - data path
    logic [31:0] ex1_imm;            // No reset - data path
    logic [4:0]  ex1_rd_addr;        // No reset - data path
    logic [3:0]  ex1_alu_op;         // No reset - data path
    
    // EX2 Stage Registers
    logic [31:0] ex2_alu_in1;        // No reset - data path
    logic [31:0] ex2_alu_in2;        // No reset - data path
    logic [4:0]  ex2_rd_addr;        // No reset - data path
    logic [31:0] ex2_alu_partial;    // No reset - data path
    
    // EX3 Stage Registers
    logic [31:0] ex3_alu_result;     // No reset - data path
    logic [4:0]  ex3_rd_addr;        // No reset - data path
    
    // EX4 Stage Registers
    logic [31:0] ex4_alu_result;     // No reset - data path
    logic [4:0]  ex4_rd_addr;        // No reset - data path
    
    // EX5 Stage Registers
    logic [31:0] ex5_result;         // No reset - data path
    logic [4:0]  ex5_rd_addr;        // No reset - data path
    
    // MEM Stage Registers
    logic [31:0] mem_addr;           // No reset - data path
    logic [31:0] mem_wdata;          // No reset - data path
    logic [31:0] mem_alu_result;     // No reset - data path
    logic [4:0]  mem_rd_addr;        // No reset - data path
    
    // WB Stage Registers
    logic [31:0] wb_result;          // No reset - data path
    logic [4:0]  wb_rd_addr;         // No reset - data path
    
    // COM (Commit) Stage Registers
    logic [31:0] com_result;         // No reset - data path
    logic [4:0]  com_rd_addr;        // No reset - data path
    
    //==========================================================================
    // Control Path Registers - WITH RESET
    //==========================================================================
    logic        if_valid;
    logic        id_valid;
    logic        ex1_valid;
    logic        ex2_valid;
    logic        ex3_valid;
    logic        ex4_valid;
    logic        ex5_valid;
    logic        mem_valid;
    logic        wb_valid;
    logic        com_valid;
    
    //==========================================================================
    // Stage 1: IF - Instruction Fetch
    //==========================================================================
    riscv_if_stage if_stage_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_in      (if_pc),
        .imem_valid (imem_valid),
        .imem_rdata (imem_rdata),
        .if_pc_out  (if_pc),
        .if_inst    (if_inst),
        .if_valid   (if_valid)
    );
    
    assign imem_addr = if_pc;
    
    //==========================================================================
    // Stage 2: ID - Instruction Decode
    //==========================================================================
    riscv_id_stage id_stage_inst (
        .clk          (clk),
        .if_pc        (if_pc),
        .if_inst      (if_inst),
        .if_valid     (if_valid),
        .id_pc        (id_pc),
        .id_inst      (id_inst),
        .id_rs1_addr  (id_rs1_addr),
        .id_rs2_addr  (id_rs2_addr),
        .id_rd_addr   (id_rd_addr),
        .id_imm       (id_imm),
        .id_valid     (id_valid)
    );
    
    //==========================================================================
    // Stage 3: EX1 - Execute Stage 1 (Address Calculation)
    //==========================================================================
    riscv_ex1_stage ex1_stage_inst (
        .clk           (clk),
        .id_pc         (id_pc),
        .id_rs1_addr   (id_rs1_addr),
        .id_rs2_addr   (id_rs2_addr),
        .id_rd_addr    (id_rd_addr),
        .id_imm        (id_imm),
        .id_valid      (id_valid),
        .ex1_pc        (ex1_pc),
        .ex1_rs1_data  (ex1_rs1_data),
        .ex1_rs2_data  (ex1_rs2_data),
        .ex1_imm       (ex1_imm),
        .ex1_rd_addr   (ex1_rd_addr),
        .ex1_alu_op    (ex1_alu_op),
        .ex1_valid     (ex1_valid)
    );
    
    //==========================================================================
    // Stage 4: EX2 - Execute Stage 2 (ALU Operation Start)
    //==========================================================================
    riscv_ex2_stage ex2_stage_inst (
        .clk             (clk),
        .ex1_rs1_data    (ex1_rs1_data),
        .ex1_rs2_data    (ex1_rs2_data),
        .ex1_imm         (ex1_imm),
        .ex1_rd_addr     (ex1_rd_addr),
        .ex1_alu_op      (ex1_alu_op),
        .ex1_valid       (ex1_valid),
        .ex2_alu_in1     (ex2_alu_in1),
        .ex2_alu_in2     (ex2_alu_in2),
        .ex2_rd_addr     (ex2_rd_addr),
        .ex2_alu_partial (ex2_alu_partial),
        .ex2_valid       (ex2_valid)
    );
    
    //==========================================================================
    // Stage 5: EX3 - Execute Stage 3 (ALU Operation Continue)
    //==========================================================================
    riscv_ex3_stage ex3_stage_inst (
        .clk              (clk),
        .ex2_alu_partial  (ex2_alu_partial),
        .ex2_rd_addr      (ex2_rd_addr),
        .ex2_valid        (ex2_valid),
        .ex3_alu_result   (ex3_alu_result),
        .ex3_rd_addr      (ex3_rd_addr),
        .ex3_valid        (ex3_valid)
    );
    
    //==========================================================================
    // Stage 6: EX4 - Execute Stage 4 (ALU Operation Complete)
    //==========================================================================
    riscv_ex4_stage ex4_stage_inst (
        .clk             (clk),
        .ex3_alu_result  (ex3_alu_result),
        .ex3_rd_addr     (ex3_rd_addr),
        .ex3_valid       (ex3_valid),
        .ex4_alu_result  (ex4_alu_result),
        .ex4_rd_addr     (ex4_rd_addr),
        .ex4_valid       (ex4_valid)
    );
    
    //==========================================================================
    // Stage 7: EX5 - Execute Stage 5 (Result Forwarding)
    //==========================================================================
    riscv_ex5_stage ex5_stage_inst (
        .clk             (clk),
        .ex4_alu_result  (ex4_alu_result),
        .ex4_rd_addr     (ex4_rd_addr),
        .ex4_valid       (ex4_valid),
        .ex5_result      (ex5_result),
        .ex5_rd_addr     (ex5_rd_addr),
        .ex5_valid       (ex5_valid)
    );
    
    //==========================================================================
    // Stage 8: MEM - Memory Access
    //==========================================================================
    riscv_mem_stage mem_stage_inst (
        .clk              (clk),
        .ex5_result       (ex5_result),
        .ex5_rd_addr      (ex5_rd_addr),
        .ex5_valid        (ex5_valid),
        .dmem_rdata       (dmem_rdata),
        .dmem_valid       (dmem_valid),
        .mem_addr         (mem_addr),
        .mem_wdata        (mem_wdata),
        .mem_alu_result   (mem_alu_result),
        .mem_rd_addr      (mem_rd_addr),
        .mem_valid        (mem_valid)
    );
    
    assign dmem_addr  = mem_addr;
    assign dmem_wdata = mem_wdata;
    assign dmem_we    = mem_valid;  // Simplified
    assign dmem_be    = 4'b1111;    // Simplified
    
    //==========================================================================
    // Stage 9: WB - Write Back
    //==========================================================================
    riscv_wb_stage wb_stage_inst (
        .clk             (clk),
        .mem_alu_result  (mem_alu_result),
        .mem_rd_addr     (mem_rd_addr),
        .mem_valid       (mem_valid),
        .wb_result       (wb_result),
        .wb_rd_addr      (wb_rd_addr),
        .wb_valid        (wb_valid)
    );
    
    //==========================================================================
    // Stage 10: COM - Commit
    //==========================================================================
    riscv_com_stage com_stage_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .wb_result    (wb_result),
        .wb_rd_addr   (wb_rd_addr),
        .wb_valid     (wb_valid),
        .com_result   (com_result),
        .com_rd_addr  (com_rd_addr),
        .com_valid    (com_valid)
    );

endmodule
