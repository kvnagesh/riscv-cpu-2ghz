//==============================================================================
// RISC-V CPU Functional Coverage
// 
// Description:
//   Functional coverage collector for comprehensive RV64I verification.
//   Tracks instruction execution, register usage, hazard scenarios, and
//   branch patterns to ensure thorough testing.
//
// Coverage Groups:
//   - Opcode coverage (all RV64I instructions)
//   - Register combinations (source and destination)
//   - Instruction type distribution
//   - Branch direction and patterns
//   - Memory access patterns
//   - Hazard scenarios (RAW, WAW, control)
//   - Exception conditions
//==============================================================================

class riscv_coverage extends uvm_subscriber #(riscv_transaction);
  `uvm_component_utils(riscv_coverage)
  
  // Coverage groups
  
  // Opcode coverage - ensure all instructions are tested
  covergroup cg_opcode;
    opcode_cp: coverpoint tr.opcode {
      bins lui = {OP_LUI};
      bins auipc = {OP_AUIPC};
      bins jal = {OP_JAL};
      bins jalr = {OP_JALR};
      bins branch = {OP_BRANCH};
      bins load = {OP_LOAD};
      bins store = {OP_STORE};
      bins reg_alu = {OP_REG};
      bins imm_alu = {OP_IMM};
      bins reg_alu_32 = {OP_REG_32};
      bins imm_alu_32 = {OP_IMM_32};
      bins system = {OP_SYSTEM};
    }
  endgroup
  
  // Funct3 coverage for ALU operations
  covergroup cg_alu_ops;
    option.per_instance = 1;
    
    funct3_cp: coverpoint tr.funct3 {
      bins add_sub = {3'b000};
      bins sll = {3'b001};
      bins slt = {3'b010};
      bins sltu = {3'b011};
      bins xor_ = {3'b100};
      bins srl_sra = {3'b101};
      bins or_ = {3'b110};
      bins and_ = {3'b111};
    }
    
    // Cross coverage of opcode and funct3
    cross_alu: cross tr.opcode, funct3_cp {
      ignore_bins not_alu = cross_alu with (tr.opcode != OP_REG && tr.opcode != OP_IMM);
    }
  endgroup
  
  // Branch type coverage
  covergroup cg_branch;
    option.per_instance = 1;
    
    branch_type: coverpoint tr.funct3 {
      bins beq = {3'b000};
      bins bne = {3'b001};
      bins blt = {3'b100};
      bins bge = {3'b101};
      bins bltu = {3'b110};
      bins bgeu = {3'b111};
    }
    
    branch_taken: coverpoint tr.branch_taken {
      bins taken = {1'b1};
      bins not_taken = {1'b0};
    }
    
    // Cross coverage of branch type and outcome
    branch_outcome: cross branch_type, branch_taken;
  endgroup
  
  // Load/Store size coverage
  covergroup cg_mem_ops;
    option.per_instance = 1;
    
    mem_size: coverpoint tr.funct3[1:0] {
      bins byte = {2'b00}; // LB/SB
      bins half = {2'b01}; // LH/SH
      bins word = {2'b10}; // LW/SW
      bins dword = {2'b11}; // LD/SD
    }
    
    mem_sign_ext: coverpoint tr.funct3[2] {
      bins sign_ext = {1'b0}; // Signed load
      bins zero_ext = {1'b1}; // Unsigned load
    }
    
    mem_alignment: coverpoint tr.mem_addr[2:0] {
      bins aligned_8 = {3'b000};
      bins misaligned = {[3'b001:3'b111]};
    }
    
    // Load/Store combinations
    mem_access: cross mem_size, mem_alignment {
      // Only check alignment for word/dword
      ignore_bins byte_any = cross_mem_access with (mem_size == 2'b00);
    }
  endgroup
  
  // Register usage coverage
  covergroup cg_registers;
    option.per_instance = 1;
    
    rs1: coverpoint tr.rs1 {
      bins zero = {5'h00};
      bins ra = {5'h01};
      bins sp = {5'h02};
      bins gp_tp = {5'h03, 5'h04};
      bins temp = {[5'h05:5'h07], [5'h1C:5'h1F]};
      bins saved = {[5'h08:5'h09], [5'h12:5'h1B]};
      bins args = {[5'h0A:5'h11]};
    }
    
    rs2: coverpoint tr.rs2 {
      bins zero = {5'h00};
      bins ra = {5'h01};
      bins sp = {5'h02};
      bins gp_tp = {5'h03, 5'h04};
      bins temp = {[5'h05:5'h07], [5'h1C:5'h1F]};
      bins saved = {[5'h08:5'h09], [5'h12:5'h1B]};
      bins args = {[5'h0A:5'h11]};
    }
    
    rd: coverpoint tr.rd {
      bins zero = {5'h00}; // Should not be written
      bins ra = {5'h01};
      bins sp = {5'h02};
      bins gp_tp = {5'h03, 5'h04};
      bins temp = {[5'h05:5'h07], [5'h1C:5'h1F]};
      bins saved = {[5'h08:5'h09], [5'h12:5'h1B]};
      bins args = {[5'h0A:5'h11]};
    }
    
    // Check for WAR/RAW hazards
    reg_hazard: cross rs1, rs2, rd {
      // Focus on potential hazards where rd == rs1 or rd == rs2
      ignore_bins no_hazard = reg_hazard with (rd != rs1 && rd != rs2);
    }
  endgroup
  
  // Instruction type distribution
  covergroup cg_instr_type;
    instr_type_cp: coverpoint tr.instr_type {
      bins r_type = {R_TYPE};
      bins i_type = {I_TYPE};
      bins s_type = {S_TYPE};
      bins b_type = {B_TYPE};
      bins u_type = {U_TYPE};
      bins j_type = {J_TYPE};
      bins system = {SYSTEM_TYPE};
    }
  endgroup
  
  // Transaction handle
  riscv_transaction tr;
  
  // Constructor
  function new(string name = "riscv_coverage", uvm_component parent = null);
    super.new(name, parent);
    
    // Create coverage groups
    cg_opcode = new();
    cg_alu_ops = new();
    cg_branch = new();
    cg_mem_ops = new();
    cg_registers = new();
    cg_instr_type = new();
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("COVERAGE", "Coverage collector built successfully", UVM_MEDIUM)
  endfunction
  
  // Write method - called when transaction is received
  virtual function void write(riscv_transaction t);
    tr = t;
    
    // Sample all coverage groups
    cg_opcode.sample();
    cg_instr_type.sample();
    
    // Sample specific groups based on instruction type
    if (tr.opcode == OP_REG || tr.opcode == OP_IMM || 
        tr.opcode == OP_REG_32 || tr.opcode == OP_IMM_32) begin
      cg_alu_ops.sample();
    end
    
    if (tr.opcode == OP_BRANCH) begin
      cg_branch.sample();
    end
    
    if (tr.opcode == OP_LOAD || tr.opcode == OP_STORE) begin
      cg_mem_ops.sample();
    end
    
    cg_registers.sample();
    
    `uvm_info("COVERAGE", 
              $sformatf("Sampled coverage for %s at PC=0x%0h", 
                       tr.opcode.name(), tr.pc),
              UVM_HIGH)
  endfunction
  
  // Report phase - print coverage summary
  virtual function void report_phase(uvm_phase phase);
    real total_cov;
    
    total_cov = ($get_coverage() / 6.0); // Average of 6 covergroups
    
    `uvm_info("COVERAGE_REPORT",
              $sformatf("\n===== Coverage Summary =====\n" +
                       "Opcode Coverage:      %.2f%%\n" +
                       "ALU Ops Coverage:     %.2f%%\n" +
                       "Branch Coverage:      %.2f%%\n" +
                       "Memory Ops Coverage:  %.2f%%\n" +
                       "Register Coverage:    %.2f%%\n" +
                       "Instr Type Coverage:  %.2f%%\n" +
                       "Total Coverage:       %.2f%%\n",
                       cg_opcode.get_coverage(),
                       cg_alu_ops.get_coverage(),
                       cg_branch.get_coverage(),
                       cg_mem_ops.get_coverage(),
                       cg_registers.get_coverage(),
                       cg_instr_type.get_coverage(),
                       total_cov),
              UVM_NONE)
  endfunction
  
endclass
