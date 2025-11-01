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
// File: riscv_hazard_detection.sv
// Description: Hazard Detection Unit for Pipeline Control
// Purpose: Detects load-use hazards and generates stall signals for IF/ID stages
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_hazard_detection (
    // Instruction decode stage information
    input  logic [4:0]  id_rs1_addr,
    input  logic [4:0]  id_rs2_addr,
    
    // EX stage information
    input  logic [4:0]  ex_rd_addr,
    input  logic        ex_mem_read,   // 1 if EX stage is doing a load
    input  logic        ex_valid,
    
    // Hazard control outputs
    output logic        stall_if,      // Stall IF stage
    output logic        stall_id,      // Stall ID stage
    output logic        flush_ex       // Flush EX stage (insert bubble)
);

    //==========================================================================
    // Load-Use Hazard Detection
    // Stall if:
    // 1. EX stage is doing a memory read (load instruction)
    // 2. The destination register of the load matches either source register
    //    in the ID stage
    // 3. The destination register is not x0 (hardwired zero)
    //==========================================================================
    logic load_use_hazard;
    
    always_comb begin
        load_use_hazard = 1'b0;
        
        if (ex_mem_read && ex_valid && (ex_rd_addr != 5'b0)) begin
            // Check if either source register in ID matches the destination in EX
            if ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr)) begin
                load_use_hazard = 1'b1;
            end
        end
    end

    //==========================================================================
    // Stall and Flush Control
    // On load-use hazard:
    // - Stall IF and ID stages (prevent new instructions from advancing)
    // - Flush EX stage (insert a bubble/NOP)
    //==========================================================================
    assign stall_if = load_use_hazard;
    assign stall_id = load_use_hazard;
    assign flush_ex = load_use_hazard;

endmodule
