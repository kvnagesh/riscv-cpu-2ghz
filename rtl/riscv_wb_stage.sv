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
// File: riscv_wb_stage.sv
// Description: Write Back Stage (Stage 9 of 10-stage pipeline)
// Purpose: Prepare data for register file write
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_wb_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] mem_result,        // Result from memory stage
    input  logic [4:0]  mem_rd_addr,       // Destination register
    input  logic        mem_valid,
    output logic [31:0] wb_data,           // NO RESET - Data path
    output logic [4:0]  wb_rd_addr,        // NO RESET - Data path
    output logic        wb_valid           // WITH RESET - Control path
);

//==============================================================================
// Pipeline Registers - Data Path (NO RESET)
//==============================================================================
    always_ff @(posedge clk) begin
        wb_data    <= mem_result;
        wb_rd_addr <= mem_rd_addr;
    end

//==============================================================================
// Pipeline Registers - Control Path (WITH RESET)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wb_valid <= 1'b0;
        else
            wb_valid <= mem_valid;
    end

endmodule
