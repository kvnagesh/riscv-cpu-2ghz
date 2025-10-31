//==============================================================================
// File: riscv_regfile.sv
// Description: 32-Register File with 2 Read Ports and 1 Write Port
// Purpose: High-speed register file with forwarding support
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_regfile (
    input  logic        clk,
    input  logic        rst_n,
    // Read Port 1
    input  logic [4:0]  rs1_addr,
    output logic [31:0] rs1_data,          // NO RESET - Data path
    // Read Port 2
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs2_data,          // NO RESET - Data path
    // Write Port
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    input  logic        wen                // Write enable
);

//==============================================================================
// Register Array (NO RESET - Data path)
//==============================================================================
    // 32 registers: x0-x31
    // x0 is hardwired to 0
    logic [31:0] registers [1:31];         // x1-x31 (x0 not stored)

//==============================================================================
// Write Operation
//==============================================================================
    always_ff @(posedge clk) begin
        if (wen && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= rd_data;
        end
    end

//==============================================================================
// Read Port 1 - Combinational with Forwarding
//==============================================================================
    always_comb begin
        if (rs1_addr == 5'd0)
            rs1_data = 32'd0;              // x0 always reads 0
        else if (wen && (rs1_addr == rd_addr))
            rs1_data = rd_data;            // Forwarding from write port
        else
            rs1_data = registers[rs1_addr];
    end

//==============================================================================
// Read Port 2 - Combinational with Forwarding
//==============================================================================
    always_comb begin
        if (rs2_addr == 5'd0)
            rs2_data = 32'd0;              // x0 always reads 0
        else if (wen && (rs2_addr == rd_addr))
            rs2_data = rd_data;            // Forwarding from write port
        else
            rs2_data = registers[rs2_addr];
    end

endmodule
