//==============================================================================
// File: riscv_ex4_stage.sv
// Description: Execute Stage 4 (EX4) - Stage 6 of 10
// Purpose: ALU operation complete (cycle 3 of 3-stage ALU)
//==============================================================================

module riscv_ex4_stage (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] ex3_alu_result,
    input  logic [4:0]  ex3_rd_addr,
    input  logic        ex3_valid,
    output logic [31:0] ex4_alu_result,    // NO RESET - Data path
    output logic [4:0]  ex4_rd_addr,       // NO RESET - Data path
    output logic        ex4_valid          // WITH RESET - Control path
);
    always_ff @(posedge clk) begin
        ex4_alu_result <= ex3_alu_result;
        ex4_rd_addr    <= ex3_rd_addr;
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) ex4_valid <= 1'b0;
        else ex4_valid <= ex3_valid;
    end
endmodule
