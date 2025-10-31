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
// File: riscv_id_stage.sv
// Description: Instruction Decode Stage (ID) - Stage 2 of 10 - RV64I Support
// Purpose: Decodes RV64I instructions, reads registers, generates immediates
// Critical Path: < 500ps for 2 GHz @ 7nm
//
// RV64I Instruction Support:
// - Integer Computational: ADD, SUB, ADDI, ADDW, ADDIW, SUBW, AND, OR, XOR,
//   ANDI, ORI, XORI, SLL, SRL, SRA, SLLI, SRLI, SRAI, SLLW, SRLW, SRAW,
//   SLLIW, SRLIW, SRAIW, SLT, SLTU, SLTI, SLTIU, LUI, AUIPC
// - Control Transfer: JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU
// - Load: LB, LH, LW, LD, LBU, LHU, LWU
// - Store: SB, SH, SW, SD
// - System: FENCE, ECALL, EBREAK
//==============================================================================

module riscv_id_stage (
    input  logic        clk,
    input  logic        rst_n,
    
    // Inputs from IF Stage - 64-bit PC, 32-bit instruction
    input  logic [63:0] if_pc,
    input  logic [31:0] if_inst,
    input  logic        if_valid,
    
    // Outputs to EX1 Stage - Pipeline Registers (64-bit data path)
    output logic [63:0] id_pc,        // NO RESET - Data path
    output logic [31:0] id_inst,      // NO RESET - Data path
    output logic [4:0]  id_rs1_addr,  // NO RESET - Data path
    output logic [4:0]  id_rs2_addr,  // NO RESET - Data path
    output logic [4:0]  id_rd_addr,   // NO RESET - Data path
    output logic [63:0] id_imm,       // NO RESET - Data path (64-bit immediate)
    output logic [5:0]  id_alu_op,    // NO RESET - Data path (expanded for RV64I)
    output logic [2:0]  id_funct3,    // NO RESET - Data path (for branch/load/store)
    output logic        id_is_32bit,  // NO RESET - Data path (W-suffix instructions)
    output logic        id_valid      // WITH RESET - Control path
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
    logic [63:0] imm_decode;
    logic [5:0]  alu_op_decode;
    logic        is_32bit_decode;
    logic [5:0]  shamt;  // Shift amount (6-bit for 64-bit, 5-bit for 32-bit W-ops)

    //==========================================================================
    // Instruction Field Extraction
    //==========================================================================
    assign opcode = if_inst[6:0];
    assign funct3 = if_inst[14:12];
    assign funct7 = if_inst[31:25];
    assign rs1_addr_decode = if_inst[19:15];
    assign rs2_addr_decode = if_inst[24:20];
    assign rd_addr_decode  = if_inst[11:7];
    assign shamt = if_inst[25:20];  // 6-bit shift amount for RV64I
    
    //==========================================================================
    // Immediate Generation (Combinational) - Sign-extended to 64 bits
    //==========================================================================
    always_comb begin
        imm_decode = 64'h0;
        case (opcode)
            // I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADDIW, SLLIW, SRLIW, SRAIW
            // I-type: LB, LH, LW, LD, LBU, LHU, LWU, JALR
            7'b0010011, 7'b0011011, 7'b0000011, 7'b1100111: begin
                imm_decode = {{52{if_inst[31]}}, if_inst[31:20]};
            end
            
            // S-type: SB, SH, SW, SD
            7'b0100011: begin
                imm_decode = {{52{if_inst[31]}}, if_inst[31:25], if_inst[11:7]};
            end
            
            // B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                imm_decode = {{51{if_inst[31]}}, if_inst[31], if_inst[7], 
                              if_inst[30:25], if_inst[11:8], 1'b0};
            end
            
            // U-type: LUI, AUIPC
            7'b0110111, 7'b0010111: begin
                imm_decode = {{32{if_inst[31]}}, if_inst[31:12], 12'h0};
            end
            
            // J-type: JAL
            7'b1101111: begin
                imm_decode = {{43{if_inst[31]}}, if_inst[31], if_inst[19:12], 
                              if_inst[20], if_inst[30:21], 1'b0};
            end
            
            default: imm_decode = 64'h0;
        endcase
    end
    
    //==========================================================================
    // ALU Operation Decode - Complete RV64I Support
    // ALU_OP Encoding (6-bit to support all RV64I operations):
    // 6'h00: ADD     | 6'h01: SUB     | 6'h02: AND     | 6'h03: OR
    // 6'h04: XOR     | 6'h05: SLL     | 6'h06: SRL     | 6'h07: SRA
    // 6'h08: SLT     | 6'h09: SLTU    | 6'h0A: LUI     | 6'h0B: AUIPC
    // 6'h0C: ADDW    | 6'h0D: SUBW    | 6'h0E: SLLW    | 6'h0F: SRLW
    // 6'h10: SRAW    | 6'h11: BEQ     | 6'h12: BNE     | 6'h13: BLT
    // 6'h14: BGE     | 6'h15: BLTU    | 6'h16: BGEU    | 6'h17: JAL
    // 6'h18: JALR    | 6'h19: LOAD    | 6'h1A: STORE   | 6'h1B: FENCE
    // 6'h1C: ECALL   | 6'h1D: EBREAK
    //==========================================================================
    always_comb begin
        alu_op_decode = 6'h00;    // Default: ADD
        is_32bit_decode = 1'b0;   // Default: 64-bit operation
        
        case (opcode)
            // R-type and I-type ALU (64-bit): ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
            7'b0110011, 7'b0010011: begin
                case (funct3)
                    3'b000: begin  // ADD/ADDI or SUB
                        if (opcode[5] && funct7[5])
                            alu_op_decode = 6'h01;  // SUB
                        else
                            alu_op_decode = 6'h00;  // ADD/ADDI
                    end
                    3'b111: alu_op_decode = 6'h02;  // AND/ANDI
                    3'b110: alu_op_decode = 6'h03;  // OR/ORI
                    3'b100: alu_op_decode = 6'h04;  // XOR/XORI
                    3'b001: alu_op_decode = 6'h05;  // SLL/SLLI
                    3'b101: begin  // SRL/SRLI or SRA/SRAI
                        alu_op_decode = funct7[5] ? 6'h07 : 6'h06;  // SRA/SRAI : SRL/SRLI
                    end
                    3'b010: alu_op_decode = 6'h08;  // SLT/SLTI
                    3'b011: alu_op_decode = 6'h09;  // SLTU/SLTIU
                    default: alu_op_decode = 6'h00;
                endcase
            end
            
            // R-type and I-type ALU (32-bit W-suffix): ADDW, SUBW, SLLW, SRLW, SRAW
            7'b0111011, 7'b0011011: begin
                is_32bit_decode = 1'b1;  // 32-bit operation (sign-extend result to 64)
                case (funct3)
                    3'b000: begin  // ADDW/ADDIW or SUBW
                        if (opcode[5] && funct7[5])
                            alu_op_decode = 6'h0D;  // SUBW
                        else
                            alu_op_decode = 6'h0C;  // ADDW/ADDIW
                    end
                    3'b001: alu_op_decode = 6'h0E;  // SLLW/SLLIW
                    3'b101: begin  // SRLW/SRLIW or SRAW/SRAIW
                        alu_op_decode = funct7[5] ? 6'h10 : 6'h0F;  // SRAW/SRAIW : SRLW/SRLIW
                    end
                    default: alu_op_decode = 6'h0C;  // Default to ADDW
                endcase
            end
            
            // LUI: Load Upper Immediate
            7'b0110111: begin
                alu_op_decode = 6'h0A;
            end
            
            // AUIPC: Add Upper Immediate to PC
            7'b0010111: begin
                alu_op_decode = 6'h0B;
            end
            
            // Branch instructions: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                case (funct3)
                    3'b000: alu_op_decode = 6'h11;  // BEQ
                    3'b001: alu_op_decode = 6'h12;  // BNE
                    3'b100: alu_op_decode = 6'h13;  // BLT
                    3'b101: alu_op_decode = 6'h14;  // BGE
                    3'b110: alu_op_decode = 6'h15;  // BLTU
                    3'b111: alu_op_decode = 6'h16;  // BGEU
                    default: alu_op_decode = 6'h11;  // Default BEQ
                endcase
            end
            
            // JAL: Jump and Link
            7'b1101111: begin
                alu_op_decode = 6'h17;
            end
            
            // JALR: Jump and Link Register
            7'b1100111: begin
                alu_op_decode = 6'h18;
            end
            
            // Load instructions: LB, LH, LW, LD, LBU, LHU, LWU
            7'b0000011: begin
                alu_op_decode = 6'h19;  // Address calculation uses ADD
            end
            
            // Store instructions: SB, SH, SW, SD
            7'b0100011: begin
                alu_op_decode = 6'h1A;  // Address calculation uses ADD
            end
            
            // FENCE
            7'b0001111: begin
                alu_op_decode = 6'h1B;
            end
            
            // ECALL, EBREAK
            7'b1110011: begin
                if (if_inst[20])
                    alu_op_decode = 6'h1D;  // EBREAK
                else
                    alu_op_decode = 6'h1C;  // ECALL
            end
            
            default: alu_op_decode = 6'h00;  // Default ADD
        endcase
    end
    
    //==========================================================================
    // Pipeline Registers - NO RESET (Data Path)
    // All data path registers pass through without reset for optimal timing
    //==========================================================================
    always_ff @(posedge clk) begin
        id_pc       <= if_pc;
        id_inst     <= if_inst;
        id_rs1_addr <= rs1_addr_decode;
        id_rs2_addr <= rs2_addr_decode;
        id_rd_addr  <= rd_addr_decode;
        id_imm      <= imm_decode;
        id_alu_op   <= alu_op_decode;
        id_funct3   <= funct3;
        id_is_32bit <= is_32bit_decode;
    end
    
    //==========================================================================
    // Valid Signal - WITH RESET (Control Path)
    // Only control signals have reset for proper initialization
    //==========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            id_valid <= 1'b0;
        else
            id_valid <= if_valid;
    end

endmodule
