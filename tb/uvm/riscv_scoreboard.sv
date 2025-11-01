//==============================================================================
// RISC-V CPU UVM Scoreboard
// 
// Description:
//   UVM scoreboard that compares actual CPU results from monitor against
//   expected results from reference model. Verifies register writebacks,
//   branch decisions, and instruction execution correctness.
//
// Features:
//   - Receives transactions from monitor via analysis port
//   - Uses reference model to generate expected results
//   - Compares actual vs expected register values
//   - Verifies branch/jump outcomes
//   - Tracks pass/fail counts
//   - Generates final test report
//   - Comprehensive error logging with details
//==============================================================================

class riscv_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(riscv_scoreboard)
  
  // Analysis port from monitor
  uvm_analysis_imp #(riscv_transaction, riscv_scoreboard) ap;
  
  // Reference model
  riscv_ref_model ref_model;
  
  // Scoreboard statistics
  int pass_count;
  int fail_count;
  int total_count;
  
  // Constructor
  function new(string name = "riscv_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  // Build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    ap = new("ap", this);
    
    // Create reference model
    ref_model = new();
    
    // Initialize counters
    pass_count = 0;
    fail_count = 0;
    total_count = 0;
    
    `uvm_info("SCOREBOARD", "Scoreboard built successfully", UVM_MEDIUM)
  endfunction
  
  // Write method - called when monitor sends transaction
  virtual function void write(riscv_transaction tr);
    bit [63:0] expected_result;
    bit match;
    
    total_count++;
    
    `uvm_info("SCOREBOARD", 
              $sformatf("Checking instruction at PC=0x%0h, opcode=%s", 
                       tr.pc, tr.opcode.name()), 
              UVM_HIGH)
    
    // Execute instruction in reference model to get expected result
    expected_result = ref_model.execute(tr);
    
    // Compare results for instructions that write to registers
    if (tr.rd_wen && tr.rd != 0) begin
      if (tr.rd_data == expected_result) begin
        match = 1;
        pass_count++;
        `uvm_info("SCOREBOARD", 
                  $sformatf("PASS: PC=0x%0h, rd=%0d, actual=0x%0h, expected=0x%0h",
                           tr.pc, tr.rd, tr.rd_data, expected_result),
                  UVM_HIGH)
      end else begin
        match = 0;
        fail_count++;
        `uvm_error("SCOREBOARD", 
                   $sformatf("FAIL: Register mismatch at PC=0x%0h\n" +
                            "  Instruction: %s\n" +
                            "  Dest reg: x%0d\n" +
                            "  Actual:   0x%016h\n" +
                            "  Expected: 0x%016h",
                            tr.pc, tr.opcode.name(), tr.rd, 
                            tr.rd_data, expected_result))
      end
    end else begin
      // Instructions that don't write registers (stores, branches)
      pass_count++;
      `uvm_info("SCOREBOARD", 
                $sformatf("Instruction completed: PC=0x%0h, %s",
                         tr.pc, tr.opcode.name()),
                UVM_HIGH)
    end
    
    // Verify branch decisions for branch instructions
    if (tr.opcode == OP_BRANCH) begin
      bit [63:0] rs1_val = ref_model.get_reg(tr.rs1);
      bit [63:0] rs2_val = ref_model.get_reg(tr.rs2);
      bit expected_taken = ref_model.eval_branch(tr.funct3, rs1_val, rs2_val);
      
      if (tr.branch_taken != expected_taken) begin
        fail_count++;
        `uvm_error("SCOREBOARD",
                   $sformatf("BRANCH MISMATCH at PC=0x%0h\n" +
                            "  Branch type: funct3=%0d\n" +
                            "  rs1=x%0d (0x%0h), rs2=x%0d (0x%0h)\n" +
                            "  Actual taken: %0b\n" +
                            "  Expected taken: %0b",
                            tr.pc, tr.funct3, 
                            tr.rs1, rs1_val, tr.rs2, rs2_val,
                            tr.branch_taken, expected_taken))
      end
    end
    
  endfunction
  
  // Report phase - print final statistics
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD_REPORT",
              $sformatf("\n===== Scoreboard Results =====\nPassed: %0d\nFailed: %0d\nTotal: %0d\n",
                       pass_count, fail_count, pass_count + fail_count), UVM_NONE)
    
    if (fail_count == 0)
      `uvm_info("TEST_PASSED", "All checks passed!", UVM_NONE)
    else
      `uvm_error("TEST_FAILED", $sformatf("%0d checks failed", fail_count))
  endfunction
  
endclass
