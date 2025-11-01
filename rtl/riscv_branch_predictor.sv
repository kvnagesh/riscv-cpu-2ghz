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
// File: riscv_branch_predictor.sv
// Description: 2-bit Saturating Counter Branch Predictor with Branch Target Buffer
// Purpose: Predicts branch outcomes to reduce control hazard penalties
// Critical Path: < 500ps for 2 GHz @ 7nm
// Prediction Table: 256 entries (8-bit index from PC)
//==============================================================================

module riscv_branch_predictor (
    input  logic         clk,
    input  logic         rst_n,
    
    // Fetch stage interface
    input  logic [63:0]  if_pc,              // Current PC being fetched
    output logic         predict_taken,      // Prediction: 1=taken, 0=not taken
    output logic [63:0]  predict_target,     // Predicted target address
    
    // Update from EX stage (actual branch resolution)
    input  logic         branch_resolved,    // Branch was resolved in EX
    input  logic [63:0]  branch_pc,          // PC of resolved branch
    input  logic         branch_actual,      // Actual outcome: 1=taken, 0=not taken
    input  logic [63:0]  branch_target       // Actual target address
);

    // Prediction table parameters
    localparam TABLE_SIZE = 256;
    localparam INDEX_WIDTH = 8;
    
    // 2-bit saturating counter states:
    // 2'b00: Strongly Not Taken
    // 2'b01: Weakly Not Taken  
    // 2'b10: Weakly Taken
    // 2'b11: Strongly Taken
    logic [1:0] prediction_table [TABLE_SIZE-1:0];
    
    // Branch Target Buffer (BTB)
    logic [63:0] btb [TABLE_SIZE-1:0];
    logic btb_valid [TABLE_SIZE-1:0];
    
    // Index generation (use lower bits of PC)
    logic [INDEX_WIDTH-1:0] if_index;
    logic [INDEX_WIDTH-1:0] branch_index;
    
    assign if_index = if_pc[INDEX_WIDTH+1:2];        // Word-aligned PC
    assign branch_index = branch_pc[INDEX_WIDTH+1:2];

    //==========================================================================
    // Prediction Logic (Combinational)
    //==========================================================================
    always_comb begin
        // Predict taken if counter is in upper half (10 or 11)
        predict_taken = prediction_table[if_index][1];
        
        // Get predicted target from BTB
        if (btb_valid[if_index])
            predict_target = btb[if_index];
        else
            predict_target = if_pc + 64'd4;  // Default sequential
    end

    //==========================================================================
    // Prediction Table Update (Sequential)
    // Update on branch resolution with 2-bit saturating counter
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all counters to weakly not taken
            for (int i = 0; i < TABLE_SIZE; i++) begin
                prediction_table[i] <= 2'b01;  // Weakly not taken
                btb_valid[i] <= 1'b0;
                btb[i] <= 64'h0;
            end
        end else if (branch_resolved) begin
            // Update prediction counter
            case (prediction_table[branch_index])
                2'b00: begin // Strongly Not Taken
                    if (branch_actual)
                        prediction_table[branch_index] <= 2'b01;  // -> Weakly Not Taken
                end
                2'b01: begin // Weakly Not Taken
                    if (branch_actual)
                        prediction_table[branch_index] <= 2'b10;  // -> Weakly Taken
                    else
                        prediction_table[branch_index] <= 2'b00;  // -> Strongly Not Taken
                end
                2'b10: begin // Weakly Taken
                    if (branch_actual)
                        prediction_table[branch_index] <= 2'b11;  // -> Strongly Taken
                    else
                        prediction_table[branch_index] <= 2'b01;  // -> Weakly Not Taken
                end
                2'b11: begin // Strongly Taken
                    if (!branch_actual)
                        prediction_table[branch_index] <= 2'b10;  // -> Weakly Taken
                end
            endcase
            
            // Update BTB on taken branches
            if (branch_actual) begin
                btb[branch_index] <= branch_target;
                btb_valid[branch_index] <= 1'b1;
            end
        end
    end

endmodule
