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
// File: riscv_alu.sv
// Description: 3-Stage Pipelined ALU for RISC-V CPU
// Purpose: High-performance arithmetic and logic operations
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_alu (
    input  logic        clk,
    input  logic        rst_n,
    // Stage 1 inputs (EX1)
    input  logic [31:0] operand_a,         // First operand
    input  logic [31:0] operand_b,         // Second operand
    input  logic [3:0]  alu_op,            // ALU operation code
    input  logic        valid_in,
    // Stage 3 outputs (EX3)
    output logic [31:0] result,            // NO RESET - Data path
    output logic        valid_out          // WITH RESET - Control path
);

    // ALU operation codes
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;  // Shift left logical
    localparam ALU_SRL  = 4'b0110;  // Shift right logical
    localparam ALU_SRA  = 4'b0111;  // Shift right arithmetic
    localparam ALU_SLT  = 4'b1000;  // Set less than
    localparam ALU_SLTU = 4'b1001;  // Set less than unsigned

//==============================================================================
// Stage 1: Operation Decode and Operand Latch
//==============================================================================
    logic [31:0] stage1_a, stage1_b;
    logic [3:0]  stage1_op;
    logic        stage1_valid;

    always_ff @(posedge clk) begin
        stage1_a  <= operand_a;
        stage1_b  <= operand_b;
        stage1_op <= alu_op;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_valid <= 1'b0;
        else
            stage1_valid <= valid_in;
    end

//==============================================================================
// Stage 2: Arithmetic/Logic Computation
//==============================================================================
    logic [31:0] stage2_result;
    logic        stage2_valid;

    always_ff @(posedge clk) begin
        case (stage1_op)
            ALU_ADD:  stage2_result <= stage1_a + stage1_b;
            ALU_SUB:  stage2_result <= stage1_a - stage1_b;
            ALU_AND:  stage2_result <= stage1_a & stage1_b;
            ALU_OR:   stage2_result <= stage1_a | stage1_b;
            ALU_XOR:  stage2_result <= stage1_a ^ stage1_b;
            ALU_SLL:  stage2_result <= stage1_a << stage1_b[4:0];
            ALU_SRL:  stage2_result <= stage1_a >> stage1_b[4:0];
            ALU_SRA:  stage2_result <= $signed(stage1_a) >>> stage1_b[4:0];
            ALU_SLT:  stage2_result <= ($signed(stage1_a) < $signed(stage1_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: stage2_result <= (stage1_a < stage1_b) ? 32'd1 : 32'd0;
            default:  stage2_result <= 32'd0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_valid <= 1'b0;
        else
            stage2_valid <= stage1_valid;
    end

//==============================================================================
// Stage 3: Result Output
//==============================================================================
    always_ff @(posedge clk) begin
        result <= stage2_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 1'b0;
        else
            valid_out <= stage2_valid;
    end

endmodule
