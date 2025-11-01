//==============================================================================
// RISC-V CPU Reference Model
// 
// Description:
//   ISA-accurate reference model that maintains architectural state and
//   executes instructions to produce expected results. Used by scoreboard
//   for functional verification.
//
// Features:
//   - Full RV64I ISA support (all instruction types)
//   - Register file tracking (x0-x31, x0 hardwired to zero)
//   - All arithmetic, logical, shift operations
//   - Branch condition evaluation
//   - Memory address calculation
//   - W-suffix 32-bit operations with sign extension
//==============================================================================

class riscv_ref_model;
  
  // Register file (x0 always 0)
  bit [63:0] regs [0:31];
  
  // Constructor
  function new();
    // Initialize all registers to 0
    for (int i = 0; i < 32; i++) begin
      regs[i] = 64'h0;
    end
  endfunction
  
  // Reset register file
  function void reset();
    for (int i = 0; i < 32; i++) begin
      regs[i] = 64'h0;
    end
  endfunction
  
  // Execute instruction and return expected result
  function bit [63:0] execute(riscv_transaction tr);
    bit [63:0] result;
    bit [63:0] rs1_val, rs2_val;
    bit [63:0] imm_val;
    bit [31:0] result_32;
    
    // Read source registers (x0 always returns 0)
    rs1_val = (tr.rs1 == 0) ? 64'h0 : regs[tr.rs1];
    rs2_val = (tr.rs2 == 0) ? 64'h0 : regs[tr.rs2];
    
    // Calculate immediate based on instruction type
    case (tr.instr_type)
      I_TYPE: imm_val = $signed(tr.instr[31:20]); // Sign-extend 12-bit
      S_TYPE: imm_val = $signed({tr.instr[31:25], tr.instr[11:7]});
      B_TYPE: imm_val = $signed({tr.instr[31], tr.instr[7], tr.instr[30:25], tr.instr[11:8], 1'b0});
      U_TYPE: imm_val = {tr.instr[31:12], 12'h0};
      J_TYPE: imm_val = $signed({tr.instr[31], tr.instr[19:12], tr.instr[20], tr.instr[30:21], 1'b0});
      default: imm_val = 64'h0;
    endcase
    
    // Execute based on opcode
    case (tr.opcode)
      
      // LUI - Load Upper Immediate
      OP_LUI: begin
        result = imm_val;
      end
      
      // AUIPC - Add Upper Immediate to PC
      OP_AUIPC: begin
        result = tr.pc + imm_val;
      end
      
      // JAL - Jump and Link
      OP_JAL: begin
        result = tr.pc + 4;
      end
      
      // JALR - Jump and Link Register
      OP_JALR: begin
        result = tr.pc + 4;
      end
      
      // BRANCH - All branch types (result is PC+4 or branch target)
      OP_BRANCH: begin
        result = tr.pc + 4; // Branch doesn't write register
      end
      
      // LOAD - All load types
      OP_LOAD: begin
        result = rs1_val + imm_val; // Memory address
      end
      
      // STORE - All store types
      OP_STORE: begin
        result = rs1_val + imm_val; // Memory address
      end
      
      // R-type ALU operations
      OP_REG: begin
        result = execute_r_type(tr.funct3, tr.funct7, rs1_val, rs2_val);
      end
      
      // I-type ALU operations
      OP_IMM: begin
        result = execute_i_type(tr.funct3, tr.funct7, rs1_val, imm_val);
      end
      
      // W-suffix 64-bit R-type (32-bit result, sign-extended)
      OP_REG_32: begin
        result_32 = execute_r_type_32(tr.funct3, tr.funct7, rs1_val[31:0], rs2_val[31:0]);
        result = $signed(result_32); // Sign-extend to 64-bit
      end
      
      // W-suffix 64-bit I-type (32-bit result, sign-extended)
      OP_IMM_32: begin
        result_32 = execute_i_type_32(tr.funct3, tr.funct7, rs1_val[31:0], imm_val[31:0]);
        result = $signed(result_32); // Sign-extend to 64-bit
      end
      
      // SYSTEM instructions
      OP_SYSTEM: begin
        result = 64'h0; // CSR operations handled separately
      end
      
      default: begin
        result = 64'h0;
      end
    endcase
    
    // Write to destination register if not x0
    if (tr.rd != 0 && tr.rd_wen) begin
      regs[tr.rd] = result;
    end
    
    return result;
  endfunction
  
  // Execute R-type instruction (64-bit)
  function bit [63:0] execute_r_type(bit [2:0] funct3, bit [6:0] funct7, bit [63:0] rs1, bit [63:0] rs2);
    bit [63:0] result;
    bit [5:0] shamt;
    
    shamt = rs2[5:0]; // Shift amount for 64-bit
    
    case (funct3)
      3'b000: begin // ADD/SUB
        if (funct7[5]) // SUB
          result = rs1 - rs2;
        else // ADD
          result = rs1 + rs2;
      end
      3'b001: result = rs1 << shamt; // SLL
      3'b010: result = ($signed(rs1) < $signed(rs2)) ? 64'h1 : 64'h0; // SLT
      3'b011: result = (rs1 < rs2) ? 64'h1 : 64'h0; // SLTU
      3'b100: result = rs1 ^ rs2; // XOR
      3'b101: begin // SRL/SRA
        if (funct7[5]) // SRA
          result = $signed(rs1) >>> shamt;
        else // SRL
          result = rs1 >> shamt;
      end
      3'b110: result = rs1 | rs2; // OR
      3'b111: result = rs1 & rs2; // AND
      default: result = 64'h0;
    endcase
    
    return result;
  endfunction
  
  // Execute I-type instruction (64-bit)
  function bit [63:0] execute_i_type(bit [2:0] funct3, bit [6:0] funct7, bit [63:0] rs1, bit [63:0] imm);
    bit [63:0] result;
    bit [5:0] shamt;
    
    shamt = imm[5:0]; // Shift amount for 64-bit
    
    case (funct3)
      3'b000: result = rs1 + imm; // ADDI
      3'b001: result = rs1 << shamt; // SLLI
      3'b010: result = ($signed(rs1) < $signed(imm)) ? 64'h1 : 64'h0; // SLTI
      3'b011: result = (rs1 < imm) ? 64'h1 : 64'h0; // SLTIU
      3'b100: result = rs1 ^ imm; // XORI
      3'b101: begin // SRLI/SRAI
        if (funct7[5]) // SRAI
          result = $signed(rs1) >>> shamt;
        else // SRLI
          result = rs1 >> shamt;
      end
      3'b110: result = rs1 | imm; // ORI
      3'b111: result = rs1 & imm; // ANDI
      default: result = 64'h0;
    endcase
    
    return result;
  endfunction
  
  // Execute R-type 32-bit instruction (W-suffix)
  function bit [31:0] execute_r_type_32(bit [2:0] funct3, bit [6:0] funct7, bit [31:0] rs1, bit [31:0] rs2);
    bit [31:0] result;
    bit [4:0] shamt;
    
    shamt = rs2[4:0]; // Shift amount for 32-bit
    
    case (funct3)
      3'b000: begin // ADDW/SUBW
        if (funct7[5]) // SUBW
          result = rs1 - rs2;
        else // ADDW
          result = rs1 + rs2;
      end
      3'b001: result = rs1 << shamt; // SLLW
      3'b101: begin // SRLW/SRAW
        if (funct7[5]) // SRAW
          result = $signed(rs1) >>> shamt;
        else // SRLW
          result = rs1 >> shamt;
      end
      default: result = 32'h0;
    endcase
    
    return result;
  endfunction
  
  // Execute I-type 32-bit instruction (W-suffix)
  function bit [31:0] execute_i_type_32(bit [2:0] funct3, bit [6:0] funct7, bit [31:0] rs1, bit [31:0] imm);
    bit [31:0] result;
    bit [4:0] shamt;
    
    shamt = imm[4:0]; // Shift amount for 32-bit
    
    case (funct3)
      3'b000: result = rs1 + imm; // ADDIW
      3'b001: result = rs1 << shamt; // SLLIW
      3'b101: begin // SRLIW/SRAIW
        if (funct7[5]) // SRAIW
          result = $signed(rs1) >>> shamt;
        else // SRLIW
          result = rs1 >> shamt;
      end
      default: result = 32'h0;
    endcase
    
    return result;
  endfunction
  
  // Evaluate branch condition
  function bit eval_branch(bit [2:0] funct3, bit [63:0] rs1, bit [63:0] rs2);
    bit taken;
    
    case (funct3)
      3'b000: taken = (rs1 == rs2); // BEQ
      3'b001: taken = (rs1 != rs2); // BNE
      3'b100: taken = ($signed(rs1) < $signed(rs2)); // BLT
      3'b101: taken = ($signed(rs1) >= $signed(rs2)); // BGE
      3'b110: taken = (rs1 < rs2); // BLTU
      3'b111: taken = (rs1 >= rs2); // BGEU
      default: taken = 1'b0;
    endcase
    
    return taken;
  endfunction
  
  // Calculate branch target
  function bit [63:0] calc_branch_target(bit [63:0] pc, bit [63:0] imm);
    return pc + imm;
  endfunction
  
  // Get register value
  function bit [63:0] get_reg(bit [4:0] reg_addr);
    return (reg_addr == 0) ? 64'h0 : regs[reg_addr];
  endfunction
  
  // Set register value
  function void set_reg(bit [4:0] reg_addr, bit [63:0] value);
    if (reg_addr != 0) begin
      regs[reg_addr] = value;
    end
  endfunction
  
endclass
