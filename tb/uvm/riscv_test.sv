//==============================================================================
// RISC-V CPU UVM Tests
// 
// Description:
//   Collection of UVM test classes for different verification scenarios.
//   Each test extends base test and runs specific sequences.
//
// Test Types:
//   - Base test (sanity)
//   - ALU test
//   - Branch test
//   - Memory test
//   - Hazard test
//   - Mixed test (comprehensive)
//==============================================================================

//==============================================================================
// Base Test - Sanity test with random instructions
//==============================================================================
class riscv_base_test extends uvm_test;
  `uvm_component_utils(riscv_base_test)
  
  // Environment
  riscv_env env;
  
  // Virtual interface
  virtual riscv_interface vif;
  
  // Constructor
  function new(string name = "riscv_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("TEST", "Failed to get virtual interface from config DB")
    end
    
    // Set interface for environment
    uvm_config_db#(virtual riscv_interface)::set(this, "env", "vif", vif);
    
    // Create environment
    env = riscv_env::type_id::create("env", this);
    
    `uvm_info("TEST", "Base test built successfully", UVM_MEDIUM)
  endfunction
  
  // Run phase
  virtual task run_phase(uvm_phase phase);
    riscv_base_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting base test", UVM_LOW)
    
    seq = riscv_base_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100; // Allow time for final transactions
    
    `uvm_info("TEST", "Base test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// ALU Test - Focus on arithmetic and logical operations
//==============================================================================
class riscv_alu_test extends riscv_base_test;
  `uvm_component_utils(riscv_alu_test)
  
  function new(string name = "riscv_alu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_alu_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting ALU test", UVM_LOW)
    
    seq = riscv_alu_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "ALU test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// Branch Test - Test control flow instructions
//==============================================================================
class riscv_branch_test extends riscv_base_test;
  `uvm_component_utils(riscv_branch_test)
  
  function new(string name = "riscv_branch_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_branch_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting branch test", UVM_LOW)
    
    seq = riscv_branch_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "Branch test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// Memory Test - Test load/store operations
//==============================================================================
class riscv_mem_test extends riscv_base_test;
  `uvm_component_utils(riscv_mem_test)
  
  function new(string name = "riscv_mem_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_mem_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting memory test", UVM_LOW)
    
    seq = riscv_mem_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "Memory test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// Hazard Test - Test pipeline hazards
//==============================================================================
class riscv_hazard_test extends riscv_base_test;
  `uvm_component_utils(riscv_hazard_test)
  
  function new(string name = "riscv_hazard_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_hazard_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting hazard test", UVM_LOW)
    
    seq = riscv_hazard_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "Hazard test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// Mixed Test - Comprehensive test with all instruction types
//==============================================================================
class riscv_mixed_test extends riscv_base_test;
  `uvm_component_utils(riscv_mixed_test)
  
  function new(string name = "riscv_mixed_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_mixed_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting mixed test", UVM_LOW)
    
    seq = riscv_mixed_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "Mixed test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass

//==============================================================================
// Reset Test - Test reset behavior
//==============================================================================
class riscv_reset_test extends riscv_base_test;
  `uvm_component_utils(riscv_reset_test)
  
  function new(string name = "riscv_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    riscv_reset_sequence seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting reset test", UVM_LOW)
    
    seq = riscv_reset_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    #100;
    
    `uvm_info("TEST", "Reset test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
