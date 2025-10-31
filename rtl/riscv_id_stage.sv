//==============================================================================
// File: riscv_id_stage.sv
// Description: Instruction Decode Stage (ID) - Stage 2 of 10
// Purpose: Decodes RISC-V instructions, reads registers, generates immediates
// Critical Path: < 500ps for 2 GHz @ 7nm
//==============================================================================

module riscv_id_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from IF Stage
    input  logic [31:0] if_pc,
    input  logic [31:0] if_inst,
    input  logic        if_valid,
    
    // Outputs to EX1 Stage - Pipeline Registers
    output logic [31:0] id_pc,             // NO RESET - Data path
    output logic [31:0] id_inst,           // NO RESET - Data path
    output logic [4:0]  id_rs1_addr,       // NO RESET - Data path
    output logic [4:0]  id_rs2_addr,       // NO RESET - Data path
    output logic [4:0]  id_rd_addr,        // NO RESET - Data path
    output logic [31:0] id_imm,            // NO RESET - Data path
    output logic [3:0]  id_alu_op,         // NO RESET - Data path
    output logic        id_valid           // WITH RESET - Control path
);

    //==========================================================================
    // Internal Decode Signals (Combinational)
    //==========================================================================
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [4:0]  rs1_addr_decode;
    logic [4:0]  rs2_addr_decode;
    logic [4:0]  rd_addr_decode;
    logic [31:0] imm_decode;
    logic [3:0]  alu_op_decode;
    
    //==========================================================================
    // Instruction Field Extraction
    //==========================================================================
    assign opcode = if_inst[6:0];
    assign funct3 = if_inst[14:12];
    assign funct7 = if_inst[31:25];
    assign rs1_addr_decode = if_inst[19:15];
    assign rs2_addr_decode = if_inst[24:20];
    assign rd_addr_decode  = if_inst[11:7];
    
    //==========================================================================
    // Immediate Generation (Combinational)
    //==========================================================================
    always_comb begin
        imm_decode = 32'h0;
        case (opcode)
            7'b0010011, 7'b0000011: begin  // I-type (ALU-imm, LOAD)
                imm_decode = {{20{if_inst[31]}}, if_inst[31:20]};
            end
            7'b0100011: begin  // S-type (STORE)
                imm_decode = {{20{if_inst[31]}}, if_inst[31:25], if_inst[11:7]};
            end
            7'b1100011: begin  // B-type (BRANCH)
                imm_decode = {{19{if_inst[31]}}, if_inst[31], if_inst[7], 
                              if_inst[30:25], if_inst[11:8], 1'b0};
            end
            7'b0110111, 7'b0010111: begin  // U-type (LUI, AUIPC)
                imm_decode = {if_inst[31:12], 12'h0};
            end
            7'b1101111: begin  // J-type (JAL)
                imm_decode = {{11{if_inst[31]}}, if_inst[31], if_inst[19:12], 
                              if_inst[20], if_inst[30:21], 1'b0};
            end
            default: imm_decode = 32'h0;
        endcase
    end
    
    //==========================================================================
    // ALU Operation Decode (Simplified)
    //==========================================================================
    always_comb begin
        alu_op_decode = 4'h0;  // Default: ADD
        case (opcode)
            7'b0110011, 7'b0010011: begin  // R-type or I-type ALU
                case (funct3)
                    3'b000: alu_op_decode = (funct7[5] & opcode[5]) ? 4'h1 : 4'h0;  // ADD/SUB
                    3'b111: alu_op_decode = 4'h2;  // AND
                    3'b110: alu_op_decode = 4'h3;  // OR
                    3'b100: alu_op_decode = 4'h4;  // XOR
                    3'b001: alu_op_decode = 4'h5;  // SLL
                    3'b101: alu_op_decode = funct7[5] ? 4'h7 : 4'h6;  // SRA/SRL
                    3'b010: alu_op_decode = 4'h8;  // SLT
                    3'b011: alu_op_decode = 4'h9;  // SLTU
                    default: alu_op_decode = 4'h0;
                endcase
            end
            default: alu_op_decode = 4'h0;  // Default ADD for loads/stores
        endcase
    end
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    //==========================================================================
    always_ff @(posedge clk) begin
        id_pc       <= if_pc;
        id_inst     <= if_inst;
        id_rs1_addr <= rs1_addr_decode;
        id_rs2_addr <= rs2_addr_decode;
        id_rd_addr  <= rd_addr_decode;
        id_imm      <= imm_decode;
        id_alu_op   <= alu_op_decode;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            id_valid <= 1'b0;
        else
            id_valid <= if_valid;
    end

endmodule
