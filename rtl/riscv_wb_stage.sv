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
// Description: Write Back Stage (WB) - Stage 9 of 10 - RV64I Support
// Purpose: Write result back to register file (64-bit)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_wb_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from MEM Stage
    input  logic [63:0] mem_pc,
    input  logic [31:0] mem_inst,
    input  logic [63:0] mem_data,      // 64-bit data to write back
    input  logic [4:0]  mem_rd_addr,
    input  logic        mem_valid,
    
    // Outputs to COM Stage - Pipeline Registers
    output logic [63:0] wb_pc,         // NO RESET - Data path
    output logic [31:0] wb_inst,       // NO RESET - Data path
    output logic [63:0] wb_data,       // NO RESET - Data path (64-bit)
    output logic [4:0]  wb_rd_addr,    // NO RESET - Data path
    output logic        wb_wr_en,      // NO RESET - Data path
    output logic        wb_valid       // WITH RESET - Control path
);
Extend riscv_wb_stage.sv to support full RV64I instruction set    // Write enable generation (simple version - always write if valid and rd != x0)
    logic wr_en;
    assign wr_en = mem_valid && (mem_rd_addr != 5'b0);
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        wb_pc      <= mem_pc;
        wb_inst    <= mem_inst;
        wb_data    <= mem_data;
        wb_rd_addr <= mem_rd_addr;
        wb_wr_en   <= wr_en;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wb_valid <= 1'b0;
        else
            wb_valid <= mem_valid;
    end

endmodule
