//==============================================================================
// RISC-V CPU UVM Environment
// 
// Description:
//   Top-level UVM environment that integrates all verification components.
//   Instantiates agent, scoreboard, and coverage collector, and connects
//   them together.
//
// Components:
//   - Agent (driver, monitor, sequencer)
//   - Scoreboard (result checking)
//   - Coverage (functional coverage collection)
//==============================================================================

class riscv_env extends uvm_env;
  `uvm_component_utils(riscv_env)
  
  // Environment components
  riscv_agent agent;
  riscv_scoreboard scoreboard;
  riscv_coverage coverage;
  
  // Virtual interface
  virtual riscv_interface vif;
  
  // Constructor
  function new(string name = "riscv_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("ENV", "Failed to get virtual interface from config DB")
    end
    
    // Set interface for agent
    uvm_config_db#(virtual riscv_interface)::set(this, "agent", "vif", vif);
    
    // Create agent
    agent = riscv_agent::type_id::create("agent", this);
    
    // Create scoreboard
    scoreboard = riscv_scoreboard::type_id::create("scoreboard", this);
    
    // Create coverage collector
    coverage = riscv_coverage::type_id::create("coverage", this);
    
    `uvm_info("ENV", "Environment built successfully", UVM_MEDIUM)
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor to scoreboard
    agent.monitor.ap.connect(scoreboard.ap);
    
    // Connect monitor to coverage
    agent.monitor.ap.connect(coverage.analysis_export);
    
    `uvm_info("ENV", "Monitor connected to scoreboard and coverage", UVM_MEDIUM)
  endfunction
  
  // End of elaboration phase - print topology
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("ENV", "\n" + this.sprint(), UVM_LOW)
  endfunction
  
endclass
