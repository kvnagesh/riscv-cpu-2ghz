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
// File: riscv_if_stage.sv
// Description: Instruction Fetch Stage (IF) - Stage 1 of 10 - RV64I Support
// Purpose: Fetches instructions from I-cache, manages 64-bit PC
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_if_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Branch/Jump control
    input  logic        branch_taken,
    input  logic [63:0] branch_target,    // 64-bit branch target address
    
    // Outputs to ID Stage - Pipeline Registers
    output logic [63:0] if_pc,            // NO RESET - Data path (64-bit PC)
    output logic [31:0] if_inst,          // NO RESET - Data path (instructions are 32-bit)
    output logic        if_valid          // WITH RESET - Control path
);

    // Program Counter (64-bit for RV64I)
    logic [63:0] pc;
    logic [63:0] next_pc;
    
    //==========================================================================
    // Next PC Calculation (Combinational)
    //==========================================================================
    always_comb begin
        if (branch_taken)
            next_pc = branch_target;
        else
            next_pc = pc + 64'd4;  // Sequential: PC + 4 (instructions are 32-bit)
    end
    
    //==========================================================================
    // Program Counter Register - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        pc <= next_pc;
    end
    
    //==========================================================================
    // Instruction Fetch from I-Cache (Placeholder)
    // In real implementation, this would interface with L1 I-cache
    //==========================================================================
    logic [31:0] fetched_inst;
    assign fetched_inst = 32'h00000013;  // NOP (ADDI x0, x0, 0) placeholder
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        if_pc   <= pc;
        if_inst <= fetched_inst;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            if_valid <= 1'b0;
        else
            if_valid <= 1'b1;  // Always valid after reset (no stalls in simple version)
    end

endmodule
