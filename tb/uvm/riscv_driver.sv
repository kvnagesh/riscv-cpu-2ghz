//==============================================================================
// UVM Driver for RISC-V RV64I CPU
// Drives transactions from sequencer to DUT via interface
//==============================================================================

`ifndef RISCV_DRIVER_SV
`define RISCV_DRIVER_SV

class riscv_driver extends uvm_driver#(riscv_transaction);
    
    `uvm_component_utils(riscv_driver)
    
    //==========================================================================
    // Interface Handle
    //==========================================================================
    virtual riscv_interface.DRIVER vif;
    
    //==========================================================================
    // Memory Model (for load/store operations)
    //==========================================================================
    bit [63:0] memory [bit[63:0]];  // Associative array for memory
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "riscv_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase - Get interface from config DB
    //==========================================================================
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual riscv_interface)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found in config DB")
        `uvm_info(get_type_name(), "Build phase complete", UVM_MEDIUM)
    endfunction
    
    //==========================================================================
    // Run Phase - Main driver loop
    //==========================================================================
    virtual task run_phase(uvm_phase phase);
        riscv_transaction tr;
        
        // Wait for reset to deassert
        wait_for_reset();
        
        forever begin
            // Get next transaction from sequencer
            seq_item_port.get_next_item(tr);
            
            `uvm_info(get_type_name(), 
                      $sformatf("Driving transaction:\n%s", tr.sprint()), 
                      UVM_HIGH)
            
            // Drive the transaction
            drive_transaction(tr);
            
            // Signal completion back to sequencer
            seq_item_port.item_done();
        end
    endtask
    
    //==========================================================================
    // Wait for Reset Deassertion
    //==========================================================================
    virtual task wait_for_reset();
        `uvm_info(get_type_name(), "Waiting for reset...", UVM_MEDIUM)
        @(posedge vif.driver_cb.rst_n);
        repeat(2) @(vif.driver_cb);  // Wait a couple cycles after reset
        `uvm_info(get_type_name(), "Reset complete", UVM_MEDIUM)
    endtask
    
    //==========================================================================
    // Drive Transaction to DUT
    //==========================================================================
    virtual task drive_transaction(riscv_transaction tr);
        // Drive instruction to IF stage
        drive_instruction(tr);
        
        // Handle memory operations if load/store
        if (tr.is_load() || tr.is_store())
            handle_memory_operation(tr);
        
        // Small delay between transactions
        repeat($urandom_range(0,2)) @(vif.driver_cb);
    endtask
    
    //==========================================================================
    // Drive Instruction to IF Stage
    //==========================================================================
    virtual task drive_instruction(riscv_transaction tr);
        // Wait for ready signal
        while (!vif.driver_cb.if_ready)
            @(vif.driver_cb);
        
        // Drive instruction and valid signal
        vif.driver_cb.if_instruction <= tr.instruction;
        vif.driver_cb.if_valid <= 1'b1;
        
        @(vif.driver_cb);
        
        // Deassert valid after one cycle (assuming single-cycle handshake)
        vif.driver_cb.if_valid <= 1'b0;
        
        `uvm_info(get_type_name(), 
                  $sformatf("Drove instruction: 0x%08x", tr.instruction), 
                  UVM_HIGH)
    endtask
    
    //==========================================================================
    // Handle Memory Operations (Load/Store)
    //==========================================================================
    virtual task handle_memory_operation(riscv_transaction tr);
        bit [63:0] addr;
        bit [63:0] data;
        int wait_cycles;
        
        // Wait for memory operation to reach MEM stage
        // This is pipeline-depth dependent (adjust for 10-stage pipeline)
        repeat(6) @(vif.driver_cb);  // Approximate cycles to reach MEM
        
        // Check if memory request is active
        if (vif.driver_cb.mem_read || vif.driver_cb.mem_write) begin
            addr = vif.driver_cb.mem_addr;
            
            if (vif.driver_cb.mem_read) begin
                // Load operation - provide data from memory model
                if (memory.exists(addr))
                    data = memory[addr];
                else
                    data = $urandom();  // Return random data for uninitialized
                
                // Apply load extension based on size
                data = apply_load_extension(data, tr.mem_size, tr.mem_unsigned);
                
                vif.driver_cb.mem_rdata <= data;
                vif.driver_cb.mem_ready <= 1'b1;
                
                `uvm_info(get_type_name(), 
                          $sformatf("LOAD: addr=0x%016x data=0x%016x", addr, data), 
                          UVM_HIGH)
            end
            else if (vif.driver_cb.mem_write) begin
                // Store operation - write to memory model
                data = vif.driver_cb.mem_wdata;
                memory[addr] = data;
                vif.driver_cb.mem_ready <= 1'b1;
                
                `uvm_info(get_type_name(), 
                          $sformatf("STORE: addr=0x%016x data=0x%016x", addr, data), 
                          UVM_HIGH)
            end
            
            @(vif.driver_cb);
            vif.driver_cb.mem_ready <= 1'b0;
        end
    endtask
    
    //==========================================================================
    // Apply Load Extension (Sign/Zero extend based on size)
    //==========================================================================
    virtual function bit [63:0] apply_load_extension(
        bit [63:0] data, 
        bit [2:0] size, 
        bit is_unsigned
    );
        case (size)
            3'b000: begin  // Byte
                if (is_unsigned)
                    return {56'b0, data[7:0]};
                else
                    return {{56{data[7]}}, data[7:0]};
            end
            3'b001: begin  // Halfword
                if (is_unsigned)
                    return {48'b0, data[15:0]};
                else
                    return {{48{data[15]}}, data[15:0]};
            end
            3'b010: begin  // Word
                if (is_unsigned)
                    return {32'b0, data[31:0]};
                else
                    return {{32{data[31]}}, data[31:0]};
            end
            3'b011: begin  // Doubleword
                return data;
            end
            default: return data;
        endcase
    endfunction
    
    //==========================================================================
    // Reset Sequence
    //==========================================================================
    virtual task reset_dut();
        `uvm_info(get_type_name(), "Asserting reset", UVM_MEDIUM)
        vif.driver_cb.rst_n <= 1'b0;
        repeat(10) @(vif.driver_cb);
        vif.driver_cb.rst_n <= 1'b1;
        `uvm_info(get_type_name(), "Reset deasserted", UVM_MEDIUM)
    endtask
    
    //==========================================================================
    // Initialize Memory with Program
    //==========================================================================
    virtual function void load_program(string filename);
        int fd;
        bit [63:0] addr;
        bit [31:0] inst;
        
        fd = $fopen(filename, "r");
        if (fd == 0) begin
            `uvm_warning(get_type_name(), 
                        $sformatf("Cannot open file: %s", filename))
            return;
        end
        
        addr = 64'h0;
        while (!$feof(fd)) begin
            $fscanf(fd, "%h", inst);
            memory[addr] = {32'h0, inst};  // Store as 64-bit aligned
            addr += 4;
        end
        
        $fclose(fd);
        `uvm_info(get_type_name(), 
                  $sformatf("Loaded %0d instructions from %s", addr/4, filename), 
                  UVM_MEDIUM)
    endfunction
    
endclass

`endif // RISCV_DRIVER_SV
