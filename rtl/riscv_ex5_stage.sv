//==============================================================================
// File: riscv_ex5_stage.sv
// Description: Execute Stage 5 (Stage 7 of 10-stage pipeline)
// Purpose: Result forwarding and bypass network preparation
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
//==============================================================================

module riscv_ex5_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] ex4_alu_result,    // NO RESET - Data path
    input  logic [4:0]  ex4_rd_addr,       // NO RESET - Data path
    input  logic        ex4_valid,
    output logic [31:0] ex5_result,        // NO RESET - Data path
    output logic [4:0]  ex5_rd_addr,       // NO RESET - Data path
    output logic        ex5_valid          // WITH RESET - Control path
);

//==============================================================================
// Pipeline Registers - Data Path (NO RESET)
//==============================================================================
    always_ff @(posedge clk) begin
        ex5_result  <= ex4_alu_result;
        ex5_rd_addr <= ex4_rd_addr;
    end

//==============================================================================
// Pipeline Registers - Control Path (WITH RESET)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ex5_valid <= 1'b0;
        else
            ex5_valid <= ex4_valid;
    end

endmodule
