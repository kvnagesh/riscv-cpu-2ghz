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
// File: riscv_ex2_stage.sv
// Description: Execute Stage 2 (EX2) - Stage 4 of 10 - RV64I Support
// Purpose: ALU computation stage 1 (64-bit operations)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex2_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX1 Stage
    input  logic [63:0] ex1_pc,
    input  logic [31:0] ex1_inst,
    input  logic [63:0] ex1_rs1_data,
    input  logic [63:0] ex1_rs2_data,
    input  logic [63:0] ex1_imm,
    input  logic [4:0]  ex1_rd_addr,
    input  logic [5:0]  ex1_alu_op,
    input  logic [2:0]  ex1_funct3,
    input  logic        ex1_is_32bit,
    input  logic        ex1_valid,
    
    // Outputs to EX3 Stage - Pipeline Registers
    output logic [63:0] ex2_pc,        // NO RESET - Data path
    output logic [31:0] ex2_inst,      // NO RESET - Data path
    output logic [63:0] ex2_alu_result, // NO RESET - Data path (64-bit)
    output logic [63:0] ex2_rs2_data,  // NO RESET - Data path (64-bit)
    output logic [4:0]  ex2_rd_addr,   // NO RESET - Data path
    output logic [2:0]  ex2_funct3,    // NO RESET - Data path
    output logic        ex2_valid      // WITH RESET - Control path
);

    // ALU interface (64-bit)
    logic [63:0] alu_result;
    logic        alu_zero;
    logic        alu_negative;
    logic        branch_taken;
    
    //==========================================================================
    // ALU Instantiation (64-bit operations)
    //==========================================================================
    riscv_alu alu_inst (
        .operand_a(ex1_rs1_data),
        .operand_b(ex1_imm),       // Or rs2_data depending on instruction type
        .alu_op(ex1_alu_op),
        .is_32bit(ex1_is_32bit),
        .result(alu_result),
        .zero(alu_zero),
        .negative(alu_negative),
        .branch_taken(branch_taken)
    );
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex2_pc         <= ex1_pc;
        ex2_inst       <= ex1_inst;
        ex2_alu_result <= alu_result;
        ex2_rs2_data   <= ex1_rs2_data;
        ex2_rd_addr    <= ex1_rd_addr;
        ex2_funct3     <= ex1_funct3;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex2_valid <= 1'b0;
        else
            ex2_valid <= ex1_valid;
    end

endmodule
