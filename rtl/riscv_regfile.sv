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
// File: riscv_regfile.sv
// Description: 64-bit Register File with 2 Read Ports and 1 Write Port - RV64I
// Purpose: 32 general-purpose 64-bit registers (x0-x31) with x0 hardwired to 0
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_regfile (
    input  logic        clk,
    input  logic        rst_n,
    
    // Read Port 1
    input  logic [4:0]  rs1_addr,
    output logic [63:0] rs1_data,      // 64-bit read data
    
    // Read Port 2
    input  logic [4:0]  rs2_addr,
    output logic [63:0] rs2_data,      // 64-bit read data
    
    // Write Port
    input  logic [4:0]  rd_addr,
    input  logic [63:0] rd_data,       // 64-bit write data
    input  logic        wr_en
);

    // 32 x 64-bit registers
    logic [63:0] registers [0:31];
    
    //==========================================================================
    // Combinational Read (Asynchronous Read)
    // x0 is hardwired to 0
    //==========================================================================
    assign rs1_data = (rs1_addr == 5'b0) ? 64'h0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 64'h0 : registers[rs2_addr];
    
    //==========================================================================
    // Sequential Write (Synchronous Write)
    // x0 is read-only (writes to x0 are ignored)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 64'h0;
            end
        end else if (wr_en && (rd_addr != 5'b0)) begin
            // Write to register (except x0)
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
