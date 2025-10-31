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
// Description: Execute Stage 2 (EX2) - Stage 4 of 10
// Purpose: ALU operation start (cycle 1 of 3-stage ALU)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex2_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX1 Stage
    input  logic [31:0] ex1_rs1_data,
    input  logic [31:0] ex1_rs2_data,
    input  logic [31:0] ex1_imm,
    input  logic [4:0]  ex1_rd_addr,
    input  logic [3:0]  ex1_alu_op,
    input  logic        ex1_valid,
    
    // Outputs to EX3 Stage - Pipeline Registers
    output logic [31:0] ex2_alu_in1,       // NO RESET - Data path
    output logic [31:0] ex2_alu_in2,       // NO RESET - Data path
    output logic [4:0]  ex2_rd_addr,       // NO RESET - Data path
    output logic [3:0]  ex2_alu_op,        // NO RESET - Data path
    output logic [31:0] ex2_alu_partial,   // NO RESET - Data path
    output logic        ex2_valid          // WITH RESET - Control path
);

    //==========================================================================
    // ALU Input Selection (Combinational)
    //==========================================================================
    logic [31:0] alu_in1_comb;
    logic [31:0] alu_in2_comb;
    
    // Select between register and immediate
    assign alu_in1_comb = ex1_rs1_data;
    assign alu_in2_comb = (ex1_alu_op[3]) ? ex1_imm : ex1_rs2_data;
    
    //==========================================================================
    // ALU Partial Computation - Stage 1 of 3
    // Simple operations that can start immediately
    //==========================================================================
    logic [31:0] alu_partial_result;
    
    always_comb begin
        case (ex1_alu_op[2:0])
            3'h0: alu_partial_result = alu_in1_comb + alu_in2_comb;  // ADD partial
            3'h1: alu_partial_result = alu_in1_comb - alu_in2_comb;  // SUB partial
            3'h2: alu_partial_result = alu_in1_comb & alu_in2_comb;  // AND
            3'h3: alu_partial_result = alu_in1_comb | alu_in2_comb;  // OR
            3'h4: alu_partial_result = alu_in1_comb ^ alu_in2_comb;  // XOR
            default: alu_partial_result = alu_in1_comb;              // Pass through
        endcase
    end
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex2_alu_in1     <= alu_in1_comb;
        ex2_alu_in2     <= alu_in2_comb;
        ex2_rd_addr     <= ex1_rd_addr;
        ex2_alu_op      <= ex1_alu_op;
        ex2_alu_partial <= alu_partial_result;
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
