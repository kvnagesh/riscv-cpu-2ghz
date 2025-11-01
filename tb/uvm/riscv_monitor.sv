//==============================================================================
// RISC-V CPU UVM Monitor
// 
// Description:
//   UVM monitor that observes the CPU outputs at WB stage and creates
//   transaction objects for the scoreboard. Monitors register writebacks,
//   branch outcomes, memory operations, and exceptions.
//
// Features:
//   - Samples WB stage for completed instructions
//   - Captures register writeback data
//   - Monitors branch/jump results
//   - Tracks memory operation completion
//   - Detects exceptions and interrupts
//   - Sends transactions via analysis port to scoreboard
//==============================================================================

class riscv_monitor extends uvm_monitor;
  `uvm_component_utils(riscv_monitor)
  
  // Virtual interface
  virtual riscv_interface vif;
  
  // Analysis port to send observed transactions
  uvm_analysis_port #(riscv_transaction) ap;
  
  // Constructor
  function new(string name = "riscv_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    ap = new("ap", this);
    
    // Get virtual interface from config DB
    if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MONITOR", "Failed to get virtual interface from config DB")
    end
    
    `uvm_info("MONITOR", "Monitor built successfully", UVM_MEDIUM)
  endfunction
  
  // Run phase - monitor DUT outputs
  virtual task run_phase(uvm_phase phase);
    riscv_transaction tr;
    
    `uvm_info("MONITOR", "Starting monitor run phase", UVM_MEDIUM)
    
    forever begin
      @(posedge vif.clk);
      
      // Sample WB stage when valid and not stalled
      if (vif.wb_valid && !vif.wb_stall && !vif.reset_n) begin
        // Create new transaction
        tr = riscv_transaction::type_id::create("tr");
        
        // Capture writeback information
        tr.rd = vif.wb_rd;
        tr.rd_data = vif.wb_rd_data;
        tr.rd_wen = vif.wb_rd_wen;
        tr.pc = vif.wb_pc;
        
        // Capture instruction that completed
        tr.instr = vif.wb_instr;
        
        // Decode opcode from completed instruction
        tr.opcode = opcode_e'(vif.wb_instr[6:0]);
        tr.funct3 = vif.wb_instr[14:12];
        tr.funct7 = vif.wb_instr[31:25];
        tr.rs1 = vif.wb_instr[19:15];
        tr.rs2 = vif.wb_instr[24:20];
        
        // Capture branch/jump information
        tr.branch_taken = vif.wb_branch_taken;
        tr.branch_target = vif.wb_branch_target;
        
        // Capture memory operation info
        tr.mem_addr = vif.wb_mem_addr;
        tr.mem_data = vif.wb_mem_data;
        tr.mem_wen = vif.wb_mem_wen;
        tr.mem_ren = vif.wb_mem_ren;
        
        // Capture exception information
        tr.exception = vif.wb_exception;
        tr.exception_cause = vif.wb_exception_cause;
        
        // Determine instruction type based on opcode
        case (tr.opcode)
          OP_LUI, OP_AUIPC: tr.instr_type = U_TYPE;
          OP_JAL: tr.instr_type = J_TYPE;
          OP_JALR: tr.instr_type = I_TYPE;
          OP_BRANCH: tr.instr_type = B_TYPE;
          OP_LOAD, OP_IMM, OP_IMM_32: tr.instr_type = I_TYPE;
          OP_STORE: tr.instr_type = S_TYPE;
          OP_REG, OP_REG_32: tr.instr_type = R_TYPE;
          OP_SYSTEM: tr.instr_type = SYSTEM_TYPE;
          default: tr.instr_type = I_TYPE;
        endcase
        
        // Log observed transaction
        `uvm_info("MONITOR", 
                  $sformatf("Observed instruction at PC=0x%0h, opcode=%s, rd=%0d, rd_data=0x%0h",
                           tr.pc, tr.opcode.name(), tr.rd, tr.rd_data), 
                  UVM_HIGH)
        
        // Send transaction to scoreboard via analysis port
        ap.write(tr);
      end
      
      // Monitor for reset
      if (!vif.reset_n) begin
        `uvm_info("MONITOR", "Reset detected", UVM_MEDIUM)
      end
    end
  endtask
  
endclass
