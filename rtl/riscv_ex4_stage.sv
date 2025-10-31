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
// File: riscv_ex4_stage.sv
// Description: Execute Stage 4 (EX4) - Stage 6 of 10 - RV64I Support
// Purpose: ALU computation stage 3 (64-bit)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex4_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX3 Stage
    input  logic [63:0] ex3_pc,
    input  logic [31:0] ex3_inst,
    input  logic [63:0] ex3_alu_result,
    input  logic [63:0] ex3_rs2_data,
    input  logic [4:0]  ex3_rd_addr,
    input  logic [2:0]  ex3_funct3,
    input  logic        ex3_valid,
    
    // Outputs to EX5 Stage - Pipeline Registers
    output logic [63:0] ex4_pc,         // NO RESET - Data path
    output logic [31:0] ex4_inst,       // NO RESET - Data path
    output logic [63:0] ex4_alu_result, // NO RESET - Data path (64-bit)
    output logic [63:0] ex4_rs2_data,   // NO RESET - Data path (64-bit)
    output logic [4:0]  ex4_rd_addr,    // NO RESET - Data path
    output logic [2:0]  ex4_funct3,     // NO RESET - Data path
    output logic        ex4_valid       // WITH RESET - Control path
);

    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex4_pc         <= ex3_pc;
        ex4_inst       <= ex3_inst;
        ex4_alu_result <= ex3_alu_result;
        ex4_rs2_data   <= ex3_rs2_data;
        ex4_rd_addr    <= ex3_rd_addr;
        ex4_funct3     <= ex3_funct3;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex4_valid <= 1'b0;
        else
            ex4_valid <= ex3_valid;
    end

endmodule
