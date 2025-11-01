//==============================================================================
// RISC-V CPU UVM Package
// 
// Description:
//   Package file that imports UVM and includes all testbench components.
//   This package should be imported in the top-level testbench module.
//
// Usage:
//   import uvm_pkg::*;
//   import riscv_pkg::*;
//
// Compilation Order:
//   1. UVM library
//   2. Interface (riscv_interface.sv)
//   3. This package (riscv_pkg.sv)
//   4. Top-level testbench (tb_top.sv)
//==============================================================================

package riscv_pkg;
  
  // Import UVM package
  import uvm_pkg::*;
  
  // Include UVM macros
  `include "uvm_macros.svh"
  
  // Include all testbench components in correct order
  
  // 1. Transaction class (base communication object)
  `include "riscv_transaction.sv"
  
  // 2. Reference model (standalone class, no UVM dependencies)
  `include "riscv_ref_model.sv"
  
  // 3. Sequences (generate stimuli)
  `include "riscv_sequences.sv"
  
  // 4. Driver (drives transactions to DUT)
  `include "riscv_driver.sv"
  
  // 5. Monitor (observes DUT outputs)
  `include "riscv_monitor.sv"
  
  // 6. Scoreboard (compares results)
  `include "riscv_scoreboard.sv"
  
  // 7. Coverage collector
  `include "riscv_coverage.sv"
  
  // 8. Agent (packages driver, monitor, sequencer)
  `include "riscv_agent.sv"
  
  // 9. Environment (top-level verification environment)
  `include "riscv_env.sv"
  
  // 10. Tests (various test scenarios)
  `include "riscv_test.sv"
  
endpackage : riscv_pkg
