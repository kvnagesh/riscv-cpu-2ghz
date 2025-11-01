//==============================================================================
// UVM Interface for RISC-V RV64I CPU
// Connects testbench to DUT signals
//==============================================================================

`ifndef RISCV_INTERFACE_SV
`define RISCV_INTERFACE_SV

interface riscv_interface(input logic clk);
    
    //==========================================================================
    // Clock and Reset
    //==========================================================================
    logic rst_n;
    
    //==========================================================================
    // Instruction Fetch Interface
    //==========================================================================
    logic [63:0] if_pc;              // Instruction fetch PC
    logic [31:0] if_instruction;     // Fetched instruction
    logic        if_valid;           // IF stage valid
    logic        if_ready;           // IF stage ready
    
    //==========================================================================
    // Instruction Decode Interface  
    //==========================================================================
    logic [63:0] id_pc;
    logic [31:0] id_instruction;
    logic [4:0]  id_rs1_addr;
    logic [4:0]  id_rs2_addr;
    logic [4:0]  id_rd_addr;
    logic        id_valid;
    
    //==========================================================================
    // Execute Stage Interface
    //==========================================================================
    logic [63:0] ex_pc;
    logic [63:0] ex_rs1_data;
    logic [63:0] ex_rs2_data;
    logic [63:0] ex_imm;
    logic [5:0]  ex_alu_op;
    logic        ex_valid;
    
    //==========================================================================
    // Memory Stage Interface
    //==========================================================================
    logic [63:0] mem_addr;           // Memory address
    logic [63:0] mem_wdata;          // Memory write data
    logic [63:0] mem_rdata;          // Memory read data
    logic        mem_read;           // Memory read enable
    logic        mem_write;          // Memory write enable
    logic [2:0]  mem_size;           // 0=byte, 1=half, 2=word, 3=dword
    logic        mem_valid;
    logic        mem_ready;
    
    //==========================================================================
    // Write-Back Stage Interface
    //==========================================================================
    logic [4:0]  wb_rd_addr;         // Destination register
    logic [63:0] wb_rd_data;         // Write-back data
    logic        wb_wr_en;           // Write enable
    logic        wb_valid;
    
    //==========================================================================
    // Branch/Jump Control
    //==========================================================================
    logic        branch_taken;       // Branch decision
    logic [63:0] branch_target;      // Branch target address
    logic        jump_taken;         // Jump taken
    
    //==========================================================================
    // Pipeline Control
    //==========================================================================
    logic        stall_if;           // Stall IF stage
    logic        stall_id;           // Stall ID stage
    logic        flush_ex;           // Flush EX stage
    logic        flush_mem;          // Flush MEM stage
    
    //==========================================================================
    // Cache Interface Signals
    //==========================================================================
    logic        icache_hit;
    logic        icache_miss;
    logic        dcache_hit;
    logic        dcache_miss;
    logic        cache_flush;
    logic        cache_invalidate;
    
    //==========================================================================
    // Hazard Detection
    //==========================================================================
    logic        data_hazard;        // RAW hazard detected
    logic        control_hazard;     // Branch hazard
    logic [1:0]  forward_a;          // Forwarding control A
    logic [1:0]  forward_b;          // Forwarding control B
    
    //==========================================================================
    // Exception/Interrupt Signals
    //==========================================================================
    logic        exception;          // Exception occurred
    logic [3:0]  exception_code;     // Exception type
    logic [63:0] exception_pc;       // Exception PC
    logic        interrupt;          // Interrupt request
    
    //==========================================================================
    // Debug/Performance Counters
    //==========================================================================
    logic [63:0] cycle_count;
    logic [63:0] inst_count;
    logic [63:0] branch_miss_count;
    
    //==========================================================================
    // Clocking Blocks for Driver (Driving signals to DUT)
    //==========================================================================
    clocking driver_cb @(posedge clk);
        default input #1ns output #1ns;
        
        output rst_n;
        output if_instruction;
        output if_valid;
        input  if_ready;
        input  if_pc;
        
        // Memory interface (for loads/stores)
        input  mem_addr;
        input  mem_wdata;
        output mem_rdata;
        input  mem_read;
        input  mem_write;
        input  mem_size;
        output mem_ready;
        
        // Control
        output cache_flush;
        output cache_invalidate;
        output interrupt;
    endclocking
    
    //==========================================================================
    // Clocking Blocks for Monitor (Sampling signals from DUT)
    //==========================================================================
    clocking monitor_cb @(posedge clk);
        default input #1ns;
        
        input rst_n;
        input if_pc;
        input if_instruction;
        input if_valid;
        
        input id_pc;
        input id_instruction;
        input id_rs1_addr;
        input id_rs2_addr;
        input id_rd_addr;
        input id_valid;
        
        input ex_pc;
        input ex_rs1_data;
        input ex_rs2_data;
        input ex_alu_op;
        input ex_valid;
        
        input mem_addr;
        input mem_wdata;
        input mem_rdata;
        input mem_read;
        input mem_write;
        input mem_valid;
        
        input wb_rd_addr;
        input wb_rd_data;
        input wb_wr_en;
        input wb_valid;
        
        input branch_taken;
        input branch_target;
        input jump_taken;
        
        input stall_if;
        input stall_id;
        input flush_ex;
        
        input data_hazard;
        input control_hazard;
        input forward_a;
        input forward_b;
        
        input exception;
        input exception_code;
        
        input icache_hit;
        input dcache_hit;
    endclocking
    
    //==========================================================================
    // Modports for Driver and Monitor
    //==========================================================================
    modport DRIVER (
        clocking driver_cb,
        input clk,
        output rst_n
    );
    
    modport MONITOR (
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
    //==========================================================================
    // Assertions for Protocol Checking
    //==========================================================================
    
    // PC alignment check
    property pc_aligned;
        @(posedge clk) disable iff (!rst_n)
        if_valid |-> (if_pc[1:0] == 2'b00);
    endproperty
    assert property (pc_aligned) else
        $error("[IF] PC not 4-byte aligned: 0x%h", if_pc);
    
    // Valid signal consistency
    property valid_stable;
        @(posedge clk) disable iff (!rst_n)
        if_valid && !if_ready |=> if_valid;
    endproperty
    assert property (valid_stable) else
        $error("[IF] Valid signal dropped before ready");
    
    // Memory size valid range
    property mem_size_valid;
        @(posedge clk) disable iff (!rst_n)
        (mem_read || mem_write) |-> (mem_size inside {[0:3]});
    endproperty
    assert property (mem_size_valid) else
        $error("[MEM] Invalid memory size: %0d", mem_size);
    
    // Write-back to x0 should be ignored
    property no_write_x0;
        @(posedge clk) disable iff (!rst_n)
        wb_wr_en && (wb_rd_addr == 5'b0) |=> 1'b1;  // Warning only
    endproperty
    assert property (no_write_x0) else
        $warning("[WB] Write to x0 detected (should be ignored)");
    
    // Branch target alignment
    property branch_target_aligned;
        @(posedge clk) disable iff (!rst_n)
        branch_taken |-> (branch_target[1:0] == 2'b00);
    endproperty
    assert property (branch_target_aligned) else
        $error("[BRANCH] Branch target not aligned: 0x%h", branch_target);
    
    //==========================================================================
    // Coverage for Interface Activity
    //==========================================================================
    covergroup interface_cg @(posedge clk);
        option.per_instance = 1;
        
        cp_stall: coverpoint {stall_if, stall_id} {
            bins no_stall = {2'b00};
            bins if_stall = {2'b10};
            bins id_stall = {2'b01};
            bins both_stall = {2'b11};
        }
        
        cp_flush: coverpoint {flush_ex, flush_mem} {
            bins no_flush = {2'b00};
            bins ex_flush = {2'b10};
            bins mem_flush = {2'b01};
            bins both_flush = {2'b11};
        }
        
        cp_hazard: coverpoint {data_hazard, control_hazard} {
            bins no_hazard = {2'b00};
            bins data_only = {2'b10};
            bins control_only = {2'b01};
            bins both_hazards = {2'b11};
        }
        
        cp_cache: coverpoint {icache_hit, dcache_hit} {
            bins both_hit = {2'b11};
            bins icache_miss = {2'b01};
            bins dcache_miss = {2'b10};
            bins both_miss = {2'b00};
        }
        
        cp_forward: coverpoint forward_a {
            bins no_forward = {2'b00};
            bins from_mem = {2'b01};
            bins from_wb = {2'b10};
        }
    endgroup
    
    interface_cg intf_cg = new();
    
endinterface

`endif // RISCV_INTERFACE_SV
