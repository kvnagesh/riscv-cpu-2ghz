//==============================================================================
// RISC-V CPU UVM Agent
// 
// Description:
//   UVM agent that packages driver, monitor, and sequencer together.
//   Handles instantiation, configuration, and connections between components.
//
// Configuration:
//   - Active/Passive mode support
//   - Virtual interface configuration
//   - Component enable/disable options
//==============================================================================

class riscv_agent extends uvm_agent;
  `uvm_component_utils(riscv_agent)
  
  // Agent components
  riscv_driver driver;
  riscv_monitor monitor;
  uvm_sequencer #(riscv_transaction) sequencer;
  
  // Virtual interface
  virtual riscv_interface vif;
  
  // Configuration
  bit is_active = 1; // 1=Active (has driver), 0=Passive (monitor only)
  
  // Constructor
  function new(string name = "riscv_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("AGENT", "Failed to get virtual interface from config DB")
    end
    
    // Always create monitor
    monitor = riscv_monitor::type_id::create("monitor", this);
    
    // Create driver and sequencer only in active mode
    if (is_active) begin
      driver = riscv_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(riscv_transaction)::type_id::create("sequencer", this);
    end
    
    `uvm_info("AGENT", $sformatf("Agent built in %s mode", is_active ? "ACTIVE" : "PASSIVE"), UVM_MEDIUM)
  endfunction
  
  // Connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Set virtual interface for monitor and driver
    uvm_config_db#(virtual riscv_interface)::set(this, "monitor", "vif", vif);
    
    if (is_active) begin
      uvm_config_db#(virtual riscv_interface)::set(this, "driver", "vif", vif);
      
      // Connect driver to sequencer
      driver.seq_item_port.connect(sequencer.seq_item_export);
      
      `uvm_info("AGENT", "Driver connected to sequencer", UVM_MEDIUM)
    end
    
    `uvm_info("AGENT", "Agent connections completed", UVM_MEDIUM)
  endfunction
  
endclass
