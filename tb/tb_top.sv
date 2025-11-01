//==============================================================================
// RISC-V CPU Top-Level Testbench
// 
// Description:
//   Top-level SystemVerilog module that instantiates the DUT (Device Under Test)
//   and connects it to the UVM testbench through the interface.
//
// Components:
//   - Clock and reset generation
//   - DUT instantiation (riscv_cpu_top)
//   - Interface instantiation and binding
//   - UVM test invocation
//==============================================================================

`timescale 1ns/1ps

module tb_top;
  
  import uvm_pkg::*;
  import riscv_pkg::*;
  
  // Clock and reset signals
  logic clk;
  logic reset_n;
  
  // Clock generation - 2GHz target (0.5ns period)
  initial begin
    clk = 0;
    forever #0.25 clk = ~clk; // 2GHz clock
  end
  
  // Reset generation
  initial begin
    reset_n = 0;
    #50;  // Hold reset for 50ns
    reset_n = 1;
    `uvm_info("TB_TOP", "Reset released", UVM_LOW)
  end
  
  // Instantiate interface
  riscv_interface intf(clk, reset_n);
  
  // Instantiate DUT (placeholder - replace with actual CPU module)
  // riscv_cpu_top dut (
  //   .clk(clk),
  //   .reset_n(reset_n),
  //   // Connect all interface signals
  //   .if_instr(intf.if_instr),
  //   .if_pc(intf.if_pc),
  //   .if_valid(intf.if_valid),
  //   // ... connect remaining signals ...
  // );
  
  // For now, create dummy connections for simulation
  // These will be replaced with actual DUT connections
  assign intf.if_instr = 32'h00000013; // NOP instruction
  assign intf.if_valid = 1'b1;
  assign intf.wb_valid = 1'b1;
  assign intf.wb_rd_wen = 1'b0;
  
  // UVM configuration and test start
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual riscv_interface)::set(null, "*", "vif", intf);
    
    // Enable waveform dump
    $dumpfile("riscv_cpu.vcd");
    $dumpvars(0, tb_top);
    
    // Print testbench info
    `uvm_info("TB_TOP", "================================", UVM_LOW)
    `uvm_info("TB_TOP", "RISC-V CPU UVM Testbench Started", UVM_LOW)
    `uvm_info("TB_TOP", "================================", UVM_LOW)
    
    // Run UVM test
    run_test();
  end
  
  // Timeout watchdog
  initial begin
    #1000000; // 1ms timeout
    `uvm_error("TB_TOP", "Test timeout!")
    $finish;
  end
  
  // Final block for cleanup
  final begin
    `uvm_info("TB_TOP", "================================", UVM_LOW)
    `uvm_info("TB_TOP", "Testbench Simulation Completed", UVM_LOW)
    `uvm_info("TB_TOP", "================================", UVM_LOW)
  end
  
endmodule
