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
// Description: Commit Stage (COM) - Stage 10 of 10 - RV64I Support
// Purpose: Final commit point, exception handling (64-bit)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_com_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from WB Stage
    input  logic [63:0] wb_pc,
    input  logic [31:0] wb_inst,
    input  logic [63:0] wb_data,       // 64-bit data
    input  logic [4:0]  wb_rd_addr,
    input  logic        wb_wr_en,
    input  logic        wb_valid,
    
    // Outputs - Final commit signals
    output logic [63:0] com_pc,        // NO RESET - Data path
    output logic [31:0] com_inst,      // NO RESET - Data path
    output logic [63:0] com_data,      // NO RESET - Data path (64-bit)
Extend riscv_com_stage.sv to support full RV64I instruction set    output logic        com_wr_en,     // NO RESET - Data path
    output logic        com_valid      // WITH RESET - Control path
);

    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        com_pc      <= wb_pc;
        com_inst    <= wb_inst;
        com_data    <= wb_data;
        com_rd_addr <= wb_rd_addr;
        com_wr_en   <= wb_wr_en;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            com_valid <= 1'b0;
        else
            com_valid <= wb_valid;
    end

endmodule
