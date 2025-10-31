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
// File: riscv_ex3_stage.sv
// Description: Execute Stage 3 (EX3) - Stage 5 of 10
// Purpose: ALU operation continue (cycle 2 of 3-stage ALU)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_ex3_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX2 Stage
    input  logic [31:0] ex2_alu_partial,
    input  logic [4:0]  ex2_rd_addr,
    input  logic [3:0]  ex2_alu_op,
    input  logic        ex2_valid,
    
    // Outputs to EX4 Stage - Pipeline Registers
    output logic [31:0] ex3_alu_result,    // NO RESET - Data path
    output logic [4:0]  ex3_rd_addr,       // NO RESET - Data path
    output logic        ex3_valid          // WITH RESET - Control path
);

    //==========================================================================
    // ALU Computation - Stage 2 of 3
    // Continue complex operations (shifts, etc.)
    //==========================================================================
    logic [31:0] alu_result_comb;
    
    always_comb begin
        case (ex2_alu_op[2:0])
            3'h0, 3'h1, 3'h2, 3'h3, 3'h4: begin
                // Simple ops completed in EX2, pass through
                alu_result_comb = ex2_alu_partial;
            end
            3'h5: begin  // SLL - shift left logical (continue)
                alu_result_comb = ex2_alu_partial;  // Simplified
            end
            3'h6: begin  // SRL - shift right logical
                alu_result_comb = ex2_alu_partial;  // Simplified
            end
            3'h7: begin  // SRA - shift right arithmetic
                alu_result_comb = ex2_alu_partial;  // Simplified
            end
            default: alu_result_comb = ex2_alu_partial;
        endcase
    end
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        ex3_alu_result <= alu_result_comb;
        ex3_rd_addr    <= ex2_rd_addr;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex3_valid <= 1'b0;
        else
            ex3_valid <= ex2_valid;
    end

endmodule
