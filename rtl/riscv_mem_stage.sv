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
