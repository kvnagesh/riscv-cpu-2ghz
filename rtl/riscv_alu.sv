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
// File: riscv_alu.sv
// Description: Arithmetic Logic Unit (ALU) - RV64I Full Support
// Purpose: Executes all RV64I arithmetic, logic, shift, and comparison operations
// Critical Path: < 500ps for 2 GHz @ 7nm
//
// Supported Operations:
// - 64-bit: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
// - 32-bit (W-suffix): ADDW, SUBW, SLLW, SRLW, SRAW (sign-extend result)
// - Upper Immediate: LUI, AUIPC
// - Branch Comparison: BEQ, BNE, BLT, BGE, BLTU, BGEU
// - Jump: JAL, JALR
//==============================================================================

module riscv_alu (
    input  logic [63:0] operand_a,     // First operand (64-bit)
    input  logic [63:0] operand_b,     // Second operand (64-bit)
    input  logic [5:0]  alu_op,        // ALU operation selector (6-bit for RV64I)
    input  logic        is_32bit,      // 1 = 32-bit operation (W-suffix), 0 = 64-bit
    output logic [63:0] result,        // ALU result (64-bit)
    output logic        zero,          // Result is zero flag
    output logic        negative,      // Result is negative flag
    output logic        branch_taken   // Branch condition met
);

    // Internal signals
    logic [63:0] add_result;
    logic [63:0] sub_result;
    logic [63:0] and_result;
    logic [63:0] or_result;
    logic [63:0] xor_result;
    logic [63:0] sll_result;
    logic [63:0] srl_result;
    logic [63:0] sra_result;
    logic        slt_result;
    logic        sltu_result;
    
    // 32-bit operation results (sign-extended to 64-bit)
    logic [31:0] add32_result;
    logic [31:0] sub32_result;
    logic [31:0] sll32_result;
    logic [31:0] srl32_result;
    logic [31:0] sra32_result;
    
    // Shift amounts
    logic [5:0]  shamt_64;  // For 64-bit shifts (6-bit: 0-63)
    logic [4:0]  shamt_32;  // For 32-bit shifts (5-bit: 0-31)
    
    assign shamt_64 = operand_b[5:0];
    assign shamt_32 = operand_b[4:0];

    //==========================================================================
    // 64-bit Arithmetic Operations
    //==========================================================================
    assign add_result = operand_a + operand_b;
    assign sub_result = operand_a - operand_b;
    
    //==========================================================================
    // 32-bit Arithmetic Operations (W-suffix) - Sign-extend result to 64-bit
    //==========================================================================
    assign add32_result = operand_a[31:0] + operand_b[31:0];
    assign sub32_result = operand_a[31:0] - operand_b[31:0];
    
    //==========================================================================
    // Logic Operations (same for 32-bit and 64-bit)
    //==========================================================================
    assign and_result = operand_a & operand_b;
    assign or_result  = operand_a | operand_b;
    assign xor_result = operand_a ^ operand_b;
    
    //==========================================================================
    // 64-bit Shift Operations
    //==========================================================================
    assign sll_result = operand_a << shamt_64;
    assign srl_result = operand_a >> shamt_64;
    assign sra_result = $signed(operand_a) >>> shamt_64;
    
    //==========================================================================
    // 32-bit Shift Operations (W-suffix) - Sign-extend result to 64-bit
    //==========================================================================
    assign sll32_result = operand_a[31:0] << shamt_32;
    assign srl32_result = operand_a[31:0] >> shamt_32;
    assign sra32_result = $signed(operand_a[31:0]) >>> shamt_32;
    
    //==========================================================================
    // Comparison Operations
    //==========================================================================
    assign slt_result  = $signed(operand_a) < $signed(operand_b);
    assign sltu_result = operand_a < operand_b;

    //==========================================================================
    // ALU Result Selection based on operation
    //==========================================================================
    always_comb begin
        result = 64'h0;
        branch_taken = 1'b0;
        
        case (alu_op)
            // 64-bit operations
            6'h00: result = add_result;                        // ADD
            6'h01: result = sub_result;                        // SUB
            6'h02: result = and_result;                        // AND
            6'h03: result = or_result;                         // OR
            6'h04: result = xor_result;                        // XOR
            6'h05: result = sll_result;                        // SLL
            6'h06: result = srl_result;                        // SRL
            6'h07: result = sra_result;                        // SRA
            6'h08: result = {63'b0, slt_result};               // SLT
            6'h09: result = {63'b0, sltu_result};              // SLTU
            
            // Upper immediate operations
            6'h0A: result = operand_b;                         // LUI (immediate already shifted)
            6'h0B: result = operand_a + operand_b;             // AUIPC (PC + immediate)
            
            // 32-bit operations (W-suffix) - sign-extend result
            6'h0C: result = {{32{add32_result[31]}}, add32_result};  // ADDW
            6'h0D: result = {{32{sub32_result[31]}}, sub32_result};  // SUBW
            6'h0E: result = {{32{sll32_result[31]}}, sll32_result};  // SLLW
            6'h0F: result = {{32{srl32_result[31]}}, srl32_result};  // SRLW
            6'h10: result = {{32{sra32_result[31]}}, sra32_result};  // SRAW
            
            // Branch comparisons
            6'h11: begin  // BEQ
                result = sub_result;
                branch_taken = (operand_a == operand_b);
            end
            6'h12: begin  // BNE
                result = sub_result;
                branch_taken = (operand_a != operand_b);
            end
            6'h13: begin  // BLT
                result = sub_result;
                branch_taken = $signed(operand_a) < $signed(operand_b);
            end
            6'h14: begin  // BGE
                result = sub_result;
                branch_taken = $signed(operand_a) >= $signed(operand_b);
            end
            6'h15: begin  // BLTU
                result = sub_result;
                branch_taken = operand_a < operand_b;
            end
            6'h16: begin  // BGEU
                result = sub_result;
                branch_taken = operand_a >= operand_b;
            end
            
            // Jump instructions
            6'h17: result = operand_a + 64'd4;                 // JAL (PC+4 for return address)
            6'h18: result = operand_a + 64'd4;                 // JALR (PC+4 for return address)
            
            // Load/Store address calculation
            6'h19: result = operand_a + operand_b;             // LOAD (base + offset)
            6'h1A: result = operand_a + operand_b;             // STORE (base + offset)
            
            // System instructions
            6'h1B: result = 64'h0;                             // FENCE (no ALU operation)
            6'h1C: result = 64'h0;                             // ECALL (no ALU operation)
            6'h1D: result = 64'h0;                             // EBREAK (no ALU operation)
            
            default: result = add_result;                      // Default to ADD
        endcase
    end
    
    //==========================================================================
    // Status Flags
    //==========================================================================
    assign zero     = (result == 64'h0);
    assign negative = result[63];

endmodule
