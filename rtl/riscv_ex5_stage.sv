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
// Description: Execute Stage 5 (Stage 7 of 10-stage pipeline)
// Purpose: Result forwarding and bypass network preparation
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_ex5_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] ex4_alu_result,    // NO RESET - Data path
    input  logic [4:0]  ex4_rd_addr,       // NO RESET - Data path
    input  logic        ex4_valid,
    output logic [31:0] ex5_result,        // NO RESET - Data path
    output logic [4:0]  ex5_rd_addr,       // NO RESET - Data path
    output logic        ex5_valid          // WITH RESET - Control path
);

//==============================================================================
// Pipeline Registers - Data Path (NO RESET)
//==============================================================================
    always_ff @(posedge clk) begin
        ex5_result  <= ex4_alu_result;
        ex5_rd_addr <= ex4_rd_addr;
    end

//==============================================================================
// Pipeline Registers - Control Path (WITH RESET)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex5_valid <= 1'b0;
        else
            ex5_valid <= ex4_valid;
    end

endmodule
