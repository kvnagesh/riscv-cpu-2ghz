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
// File: riscv_mem_stage.sv
// Description: Memory Access Stage (Stage 8 of 10-stage pipeline)
// Purpose: L1 data cache access and memory operations
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_mem_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] ex5_result,        // ALU result or address
    input  logic [4:0]  ex5_rd_addr,
    input  logic        ex5_valid,
    input  logic        ex5_mem_read,      // Memory read enable
    input  logic        ex5_mem_write,     // Memory write enable
    input  logic [31:0] ex5_mem_wdata,     // Memory write data
    // L1 Cache Interface
    output logic [31:0] l1_addr,
    output logic        l1_read,
    output logic        l1_write,
    output logic [31:0] l1_wdata,
    input  logic [31:0] l1_rdata,
    input  logic        l1_ready,
    // Pipeline outputs
    output logic [31:0] mem_result,        // NO RESET - Data path
    output logic [4:0]  mem_rd_addr,       // NO RESET - Data path
    output logic        mem_valid          // WITH RESET - Control path
);

//==============================================================================
// Combinational Logic - L1 Cache Interface
//==============================================================================
    assign l1_addr  = ex5_result;          // Address from ALU
    assign l1_read  = ex5_mem_read;
    assign l1_write = ex5_mem_write;
    assign l1_wdata = ex5_mem_wdata;

//==============================================================================
// Pipeline Registers - Data Path (NO RESET)
//==============================================================================
    always_ff @(posedge clk) begin
        // Select between ALU result and memory read data
        if (ex5_mem_read && l1_ready)
            mem_result <= l1_rdata;
        else
            mem_result <= ex5_result;
        
        mem_rd_addr <= ex5_rd_addr;
    end

//==============================================================================
// Pipeline Registers - Control Path (WITH RESET)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mem_valid <= 1'b0;
        else
            mem_valid <= ex5_valid && (!ex5_mem_read || l1_ready);
    end

endmodule
