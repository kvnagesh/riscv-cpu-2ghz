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
// File: riscv_ex5_stage.sv
// Description: Execute Stage 5 (EX5) - Stage 7 of 10 - RV64I Support
// Purpose: Final ALU stage before memory access (64-bit)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex5_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX4 Stage
    input  logic [63:0] ex4_pc,
    input  logic [31:0] ex4_inst,
    input  logic [63:0] ex4_alu_result,
    input  logic [63:0] ex4_rs2_data,
    input  logic [4:0]  ex4_rd_addr,
    input  logic [2:0]  ex4_funct3,
    input  logic        ex4_valid,
    
    // Outputs to MEM Stage - Pipeline Registers
    output logic [63:0] ex5_pc,         // NO RESET - Data path
    output logic [31:0] ex5_inst,       // NO RESET - Data path
    output logic [63:0] ex5_alu_result, // NO RESET - Data path (64-bit)
    output logic [63:0] ex5_rs2_data,   // NO RESET - Data path (64-bit)
    output logic [4:0]  ex5_rd_addr,    // NO RESET - Data path
    output logic [2:0]  ex5_funct3,     // NO RESET - Data path
    output logic        ex5_valid       // WITH RESET - Control path
);

    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex5_pc         <= ex4_pc;
        ex5_inst       <= ex4_inst;
        ex5_alu_result <= ex4_alu_result;
        ex5_rs2_data   <= ex4_rs2_data;
        ex5_rd_addr    <= ex4_rd_addr;
        ex5_funct3     <= ex4_funct3;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex5_valid <= 1'b0;
        else
            ex5_valid <= ex4_valid;
    end

endmodule
