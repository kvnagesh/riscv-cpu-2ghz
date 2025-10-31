//==============================================================================
// File: riscv_if_stage.sv
// Description: Instruction Fetch Stage (IF) - Stage 1 of 10
// Purpose: Fetches instructions from L1 I-cache and updates PC
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_if_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // PC Management
    input  logic [31:0] pc_in,
    output logic [31:0] if_pc_out,         // NO RESET - Data path
    
    // L1 I-Cache Interface
    input  logic [31:0] imem_rdata,
    input  logic        imem_valid,
    
    // Pipeline Outputs to ID Stage
    output logic [31:0] if_inst,           // NO RESET - Data path
    output logic        if_valid           // WITH RESET - Control path
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    
    //==========================================================================
    // PC Calculation (Combinational)
    //==========================================================================
    assign pc_plus_4 = if_pc_out + 32'd4;
    assign pc_next = pc_plus_4;  // Simple sequential PC (no branches yet)
    
    //==========================================================================
    // PC Register - NO RESET (Data Path)
    // Critical for achieving 2 GHz - no reset logic in timing path
    //==========================================================================
    always_ff @(posedge clk) begin
        if_pc_out <= pc_next;
    end
    
    //==========================================================================
    // Instruction Register - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        if_inst <= imem_rdata;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            if_valid <= 1'b0;
        else
            if_valid <= imem_valid;
    end

endmodule
