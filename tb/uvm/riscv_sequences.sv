//==============================================================================
// RISC-V CPU UVM Sequences
// 
// Description:
//   Collection of UVM sequences for generating instruction stimuli.
//   Includes base sequence class and specialized sequences for different
//   test scenarios.
//
// Sequence Types:
//   - Base sequence (random instructions)
//   - ALU operations sequence
//   - Branch/jump sequence
//   - Load/store sequence
//   - Hazard generation sequence
//   - Reset sequence
//==============================================================================

//==============================================================================
// Base Sequence - Random instruction generation
//==============================================================================
class riscv_base_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_base_sequence)
  
  rand int num_trans;
  
  constraint num_trans_c {
    num_trans inside {[10:50]};
  }
  
  function new(string name = "riscv_base_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", $sformatf("Starting sequence with %0d transactions", num_trans), UVM_MEDIUM)
    
    repeat(num_trans) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize()) begin
        `uvm_error("SEQ", "Randomization failed")
      end
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "Sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// ALU Operations Sequence - Focus on arithmetic and logical instructions
//==============================================================================
class riscv_alu_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_alu_sequence)
  
  rand int num_trans;
  
  constraint num_trans_c {
    num_trans inside {[20:40]};
  }
  
  function new(string name = "riscv_alu_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", "Starting ALU operations sequence", UVM_MEDIUM)
    
    repeat(num_trans) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {
        opcode inside {OP_REG, OP_IMM, OP_REG_32, OP_IMM_32};
      });
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "ALU sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// Branch/Jump Sequence - Test control flow instructions
//==============================================================================
class riscv_branch_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_branch_sequence)
  
  rand int num_branches;
  
  constraint num_branches_c {
    num_branches inside {[15:30]};
  }
  
  function new(string name = "riscv_branch_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", "Starting branch/jump sequence", UVM_MEDIUM)
    
    // Mix of branches, jumps, and regular instructions
    repeat(num_branches) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {
        opcode inside {OP_BRANCH, OP_JAL, OP_JALR};
      });
      finish_item(tr);
      
      // Add some ALU ops between branches
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {
        opcode inside {OP_REG, OP_IMM};
      });
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "Branch sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// Load/Store Sequence - Test memory operations
//==============================================================================
class riscv_mem_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_mem_sequence)
  
  rand int num_mem_ops;
  
  constraint num_mem_ops_c {
    num_mem_ops inside {[20:40]};
  }
  
  function new(string name = "riscv_mem_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", "Starting load/store sequence", UVM_MEDIUM)
    
    repeat(num_mem_ops) begin
      // Load instruction
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {
        opcode == OP_LOAD;
        funct3 inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100, 3'b101, 3'b110};
      });
      finish_item(tr);
      
      // Store instruction
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize() with {
        opcode == OP_STORE;
        funct3 inside {3'b000, 3'b001, 3'b010, 3'b011};
      });
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "Memory sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// Hazard Sequence - Generate RAW, WAR, WAW hazards
//==============================================================================
class riscv_hazard_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_hazard_sequence)
  
  rand int num_hazards;
  
  constraint num_hazards_c {
    num_hazards inside {[10:20]};
  }
  
  function new(string name = "riscv_hazard_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr1, tr2, tr3;
    bit [4:0] target_reg;
    
    `uvm_info("SEQ", "Starting hazard generation sequence", UVM_MEDIUM)
    
    repeat(num_hazards) begin
      // Pick a target register (not x0)
      target_reg = $urandom_range(1, 31);
      
      // Instruction 1: Write to target register
      tr1 = riscv_transaction::type_id::create("tr1");
      start_item(tr1);
      assert(tr1.randomize() with {
        opcode inside {OP_REG, OP_IMM};
        rd == target_reg;
      });
      finish_item(tr1);
      
      // Instruction 2: Use target register (RAW hazard)
      tr2 = riscv_transaction::type_id::create("tr2");
      start_item(tr2);
      assert(tr2.randomize() with {
        opcode inside {OP_REG, OP_IMM};
        rs1 == target_reg;
      });
      finish_item(tr2);
      
      // Instruction 3: Write again to same register (WAW hazard)
      tr3 = riscv_transaction::type_id::create("tr3");
      start_item(tr3);
      assert(tr3.randomize() with {
        opcode inside {OP_REG, OP_IMM};
        rd == target_reg;
      });
      finish_item(tr3);
    end
    
    `uvm_info("SEQ", "Hazard sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// Reset Sequence - Test reset behavior
//==============================================================================
class riscv_reset_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_reset_sequence)
  
  function new(string name = "riscv_reset_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    
    `uvm_info("SEQ", "Starting reset sequence", UVM_MEDIUM)
    
    // Generate a few instructions before reset
    repeat(5) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      finish_item(tr);
    end
    
    // Reset handled by driver
    #100;
    
    // Generate instructions after reset
    repeat(5) begin
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "Reset sequence completed", UVM_MEDIUM)
  endtask
  
endclass

//==============================================================================
// Mixed Instruction Sequence - Realistic mix of all instruction types
//==============================================================================
class riscv_mixed_sequence extends uvm_sequence #(riscv_transaction);
  `uvm_object_utils(riscv_mixed_sequence)
  
  rand int num_trans;
  
  constraint num_trans_c {
    num_trans inside {[50:100]};
  }
  
  function new(string name = "riscv_mixed_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    riscv_transaction tr;
    int instr_type;
    
    `uvm_info("SEQ", $sformatf("Starting mixed sequence with %0d transactions", num_trans), UVM_MEDIUM)
    
    repeat(num_trans) begin
      // Randomly choose instruction category
      instr_type = $urandom_range(0, 4);
      
      tr = riscv_transaction::type_id::create("tr");
      start_item(tr);
      
      case (instr_type)
        0: begin // ALU operations
          assert(tr.randomize() with {
            opcode inside {OP_REG, OP_IMM};
          });
        end
        1: begin // Branches
          assert(tr.randomize() with {
            opcode == OP_BRANCH;
          });
        end
        2: begin // Loads
          assert(tr.randomize() with {
            opcode == OP_LOAD;
          });
        end
        3: begin // Stores
          assert(tr.randomize() with {
            opcode == OP_STORE;
          });
        end
        4: begin // Upper immediate/Jumps
          assert(tr.randomize() with {
            opcode inside {OP_LUI, OP_AUIPC, OP_JAL, OP_JALR};
          });
        end
      endcase
      
      finish_item(tr);
    end
    
    `uvm_info("SEQ", "Mixed sequence completed", UVM_MEDIUM)
  endtask
  
endclass
