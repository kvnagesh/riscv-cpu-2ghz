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
// File: riscv_forwarding_unit.sv
// Description: Data Forwarding/Bypassing Unit for Pipeline Hazard Resolution
// Purpose: Implements operand forwarding from EX, MEM, and WB stages to avoid
//          pipeline stalls on data hazards
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_forwarding_unit (
    // Source register addresses from ID/EX stage
    input  logic [4:0]  ex_rs1_addr,
    input  logic [4:0]  ex_rs2_addr,
    
    // Destination register addresses from pipeline stages
    input  logic [4:0]  mem_rd_addr,
    input  logic [4:0]  wb_rd_addr,
    
    // Write enable signals
    input  logic        mem_wr_en,
    input  logic        wb_wr_en,
    
    // Forwarding control outputs
    output logic [1:0]  forward_a,  // 00: no forward, 01: from MEM, 10: from WB
    output logic [1:0]  forward_b   // 00: no forward, 01: from MEM, 10: from WB
);

    //==========================================================================
    // Forward Logic for Operand A (RS1)
    // Priority: MEM stage > WB stage > No forwarding
    //==========================================================================
    always_comb begin
        // Default: no forwarding
        forward_a = 2'b00;
        
        // Forward from MEM stage (highest priority)
        if (mem_wr_en && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b01;  // Forward from MEM stage
        end
        // Forward from WB stage (lower priority)
        else if (wb_wr_en && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b10;  // Forward from WB stage
        end
    end

    //==========================================================================
    // Forward Logic for Operand B (RS2)
    // Priority: MEM stage > WB stage > No forwarding
    //==========================================================================
    always_comb begin
        // Default: no forwarding
        forward_b = 2'b00;
        
        // Forward from MEM stage (highest priority)
        if (mem_wr_en && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b01;  // Forward from MEM stage
        end
        // Forward from WB stage (lower priority)
        else if (wb_wr_en && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b10;  // Forward from WB stage
        end
    end

endmodule
