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
// Description: Memory Access Stage (MEM) - Stage 8 of 10 - RV64I Support
// Purpose: Load/store operations with 64-bit support (LB, LH, LW, LD, LBU, LHU, LWU, SB, SH, SW, SD)
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_mem_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from EX5 Stage
    input  logic [63:0] ex5_pc,
    input  logic [31:0] ex5_inst,
    input  logic [63:0] ex5_alu_result,  // Address for load/store
    input  logic [63:0] ex5_rs2_data,    // Store data
    input  logic [4:0]  ex5_rd_addr,
    input  logic [2:0]  ex5_funct3,      // Determines load/store size
    input  logic        ex5_valid,
    
    // Outputs to WB Stage - Pipeline Registers
    output logic [63:0] mem_pc,          // NO RESET - Data path
    output logic [31:0] mem_inst,        // NO RESET - Data path
    output logic [63:0] mem_data,        // NO RESET - Data path (64-bit load data or ALU result)
    output logic [4:0]  mem_rd_addr,     // NO RESET - Data path
    output logic        mem_valid        // WITH RESET - Control path
);

    // Memory interface (placeholder - would connect to D-cache)
    logic [63:0] mem_read_data;
    logic [63:0] mem_addr;
    logic [63:0] mem_write_data;
    
    assign mem_addr = ex5_alu_result;
    
    //==========================================================================
    // Load Data Processing (Sign/Zero Extension)
    // funct3 encoding:
    // 3'b000: LB  (sign-extend byte)
    // 3'b001: LH  (sign-extend halfword)
    // 3'b010: LW  (sign-extend word)
    // 3'b011: LD  (doubleword - no extension needed)
    // 3'b100: LBU (zero-extend byte)
    // 3'b101: LHU (zero-extend halfword)
    // 3'b110: LWU (zero-extend word)
    //==========================================================================
    logic [63:0] load_data_processed;
    
    always_comb begin
        mem_read_data = 64'h0;  // Placeholder - would come from D-cache
        
        case (ex5_funct3)
            3'b000: load_data_processed = {{56{mem_read_data[7]}}, mem_read_data[7:0]};    // LB
            3'b001: load_data_processed = {{48{mem_read_data[15]}}, mem_read_data[15:0]};  // LH
            3'b010: load_data_processed = {{32{mem_read_data[31]}}, mem_read_data[31:0]};  // LW
            3'b011: load_data_processed = mem_read_data;                                    // LD
            3'b100: load_data_processed = {56'b0, mem_read_data[7:0]};                      // LBU
            3'b101: load_data_processed = {48'b0, mem_read_data[15:0]};                     // LHU
            3'b110: load_data_processed = {32'b0, mem_read_data[31:0]};                     // LWU
            default: load_data_processed = mem_read_data;
        endcase
    end
    
    //==========================================================================
    // Store Data Processing
    // For stores, extract appropriate bytes from rs2_data based on funct3:
    // 3'b000: SB  (byte)
    // 3'b001: SH  (halfword)
    // 3'b010: SW  (word)
    // 3'b011: SD  (doubleword)
    //==========================================================================
    always_comb begin
        case (ex5_funct3)
            3'b000: mem_write_data = {56'b0, ex5_rs2_data[7:0]};   // SB
            3'b001: mem_write_data = {48'b0, ex5_rs2_data[15:0]};  // SH
            3'b010: mem_write_data = {32'b0, ex5_rs2_data[31:0]};  // SW
            3'b011: mem_write_data = ex5_rs2_data;                 // SD
            default: mem_write_data = ex5_rs2_data;
        endcase
    end
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        mem_pc      <= ex5_pc;
        mem_inst    <= ex5_inst;
        mem_data    <= load_data_processed;  // For loads; ALU result for non-memory ops
        mem_rd_addr <= ex5_rd_addr;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mem_valid <= 1'b0;
        else
            mem_valid <= ex5_valid;
    end

endmodule
