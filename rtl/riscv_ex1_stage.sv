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
// File: riscv_ex1_stage.sv
// Description: Execute Stage 1 (EX1) - Stage 3 of 10
// Purpose: Address calculation, register file read, operand selection
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex1_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from ID Stage
    input  logic [31:0] id_pc,
    input  logic [4:0]  id_rs1_addr,
    input  logic [4:0]  id_rs2_addr,
    input  logic [4:0]  id_rd_addr,
    input  logic [31:0] id_imm,
    input  logic [3:0]  id_alu_op,
    input  logic        id_valid,
    
    // Register File Interface
    output logic [4:0]  rf_rs1_addr,
    output logic [4:0]  rf_rs2_addr,
    input  logic [31:0] rf_rs1_data,
    input  logic [31:0] rf_rs2_data,
    
    // Outputs to EX2 Stage - Pipeline Registers
    output logic [31:0] ex1_pc,            // NO RESET - Data path
    output logic [31:0] ex1_rs1_data,      // NO RESET - Data path
    output logic [31:0] ex1_rs2_data,      // NO RESET - Data path
    output logic [31:0] ex1_imm,           // NO RESET - Data path
    output logic [4:0]  ex1_rd_addr,       // NO RESET - Data path
    output logic [3:0]  ex1_alu_op,        // NO RESET - Data path
    output logic        ex1_valid          // WITH RESET - Control path
);

    //==========================================================================
    // Register File Address Assignment (Combinational)
    //==========================================================================
    assign rf_rs1_addr = id_rs1_addr;
    assign rf_rs2_addr = id_rs2_addr;
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex1_pc       <= id_pc;
        ex1_rs1_data <= rf_rs1_data;
        ex1_rs2_data <= rf_rs2_data;
        ex1_imm      <= id_imm;
        ex1_rd_addr  <= id_rd_addr;
        ex1_alu_op   <= id_alu_op;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex1_valid <= 1'b0;
        else
            ex1_valid <= id_valid;
    end

endmodule
