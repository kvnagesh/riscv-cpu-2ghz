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
// File: riscv_com_stage.sv
// Description: Commit Stage (Stage 10 of 10-stage pipeline)
// Purpose: In-order commit logic and final register file write
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_com_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] wb_data,           // Write back data
    input  logic [4:0]  wb_rd_addr,        // Destination register
    input  logic        wb_valid,          // Valid instruction
    // Register file write interface
    output logic [31:0] rf_wdata,          // NO RESET - Data path
    output logic [4:0]  rf_waddr,          // NO RESET - Data path
    output logic        rf_wen,            // WITH RESET - Control path
    output logic        com_valid          // WITH RESET - Control path
);

//==============================================================================
// Combinational Logic - Register File Write Enable
//==============================================================================
    // Only write if valid and destination is not x0
    assign rf_wen = wb_valid && (wb_rd_addr != 5'b00000);

//==============================================================================
// Pipeline Registers - Data Path (NO RESET)
//==============================================================================
    always_ff @(posedge clk) begin
        rf_wdata <= wb_data;
        rf_waddr <= wb_rd_addr;
    end

//==============================================================================
// Pipeline Registers - Control Path (WITH RESET)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            com_valid <= 1'b0;
        else
            com_valid <= wb_valid;
    end

endmodule
