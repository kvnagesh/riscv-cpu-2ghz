//==============================================================================
// UVM Transaction Class for RISC-V RV64I CPU
// Represents a single instruction transaction with all necessary fields
//==============================================================================

`ifndef RISCV_TRANSACTION_SV
`define RISCV_TRANSACTION_SV

class riscv_transaction extends uvm_sequence_item;
    
    //==========================================================================
    // Instruction Fields
    //==========================================================================
    rand bit [63:0] pc;              // Program counter
    rand bit [31:0] instruction;     // 32-bit instruction
    rand bit [6:0]  opcode;          // Opcode field
    rand bit [4:0]  rd;              // Destination register
    rand bit [4:0]  rs1;             // Source register 1
    rand bit [4:0]  rs2;             // Source register 2
    rand bit [2:0]  funct3;          // Function 3
    rand bit [6:0]  funct7;          // Function 7
    rand bit [63:0] imm;             // Immediate value (sign-extended)
    
    //==========================================================================
    // Operand Values
    //==========================================================================
    rand bit [63:0] rs1_data;        // RS1 register data
    rand bit [63:0] rs2_data;        // RS2 register data
    
    //==========================================================================
    // Expected Results
    //==========================================================================
    bit [63:0] expected_result;      // Expected ALU/MEM result
    bit [63:0] expected_pc_next;     // Expected next PC
    bit        expected_branch_taken;// Expected branch decision
    bit [63:0] expected_mem_addr;    // Expected memory address
    bit [63:0] expected_mem_data;    // Expected memory write data
    
    //==========================================================================
    // Actual Results (from monitor)
    //==========================================================================
    bit [63:0] actual_result;
    bit [63:0] actual_pc_next;
    bit        actual_branch_taken;
    bit [63:0] actual_mem_addr;
    bit [63:0] actual_mem_data;
    
    //==========================================================================
    // Control Signals
    //==========================================================================
    rand bit        mem_read;
    rand bit        mem_write;
    rand bit [2:0]  mem_size;        // 0=byte, 1=half, 2=word, 3=dword
    rand bit        mem_unsigned;    // Unsigned load extension
    rand bit        is_branch;
    rand bit        is_jump;
    rand bit        is_system;
    rand bit        is_32bit_op;     // W-suffix operation
    
    //==========================================================================
    // Instruction Type Enum
    //==========================================================================
    typedef enum {
        R_TYPE,    // Register-register
        I_TYPE,    // Immediate
        S_TYPE,    // Store
        B_TYPE,    // Branch
        U_TYPE,    // Upper immediate
        J_TYPE,    // Jump
        SYSTEM     // System instructions
    } inst_type_e;
    
    rand inst_type_e inst_type;
    
    //==========================================================================
    // Opcode Definitions (RV64I)
    //==========================================================================
    typedef enum bit [6:0] {
        OP_LUI    = 7'b0110111,
        OP_AUIPC  = 7'b0010111,
        OP_JAL    = 7'b1101111,
        OP_JALR   = 7'b1100111,
        OP_BRANCH = 7'b1100011,
        OP_LOAD   = 7'b0000011,
        OP_STORE  = 7'b0100011,
        OP_IMM    = 7'b0010011,
        OP_IMM_32 = 7'b0011011,  // W-suffix immediates
        OP_REG    = 7'b0110011,
        OP_REG_32 = 7'b0111011,  // W-suffix register ops
        OP_FENCE  = 7'b0001111,
        OP_SYSTEM = 7'b1110011
    } opcode_e;
    
    //==========================================================================
    // UVM Macros
    //==========================================================================
    `uvm_object_utils_begin(riscv_transaction)
        `uvm_field_int(pc, UVM_ALL_ON)
        `uvm_field_int(instruction, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(opcode, UVM_ALL_ON)
        `uvm_field_int(rd, UVM_ALL_ON)
        `uvm_field_int(rs1, UVM_ALL_ON)
        `uvm_field_int(rs2, UVM_ALL_ON)
        `uvm_field_int(expected_result, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(actual_result, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end
    
    //==========================================================================
    // Constraints
    //==========================================================================
    
    // Valid register addresses (x0 is read-only zero)
    constraint valid_regs_c {
        rd inside {[0:31]};
        rs1 inside {[0:31]};
        rs2 inside {[0:31]};
    }
    
    // PC alignment (must be 4-byte aligned for RV64I)
    constraint pc_align_c {
        pc[1:0] == 2'b00;
        pc[63:32] == 32'h0;  // Keep PC in lower 4GB for simplicity
    }
    
    // Valid opcode
    constraint valid_opcode_c {
        opcode inside {
            OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_BRANCH,
            OP_LOAD, OP_STORE, OP_IMM, OP_IMM_32,
            OP_REG, OP_REG_32, OP_FENCE, OP_SYSTEM
        };
    }
    
    // Instruction type matches opcode
    constraint inst_type_match_c {
        (opcode == OP_REG || opcode == OP_REG_32) -> inst_type == R_TYPE;
        (opcode == OP_IMM || opcode == OP_IMM_32 || opcode == OP_LOAD || opcode == OP_JALR) -> inst_type == I_TYPE;
        (opcode == OP_STORE) -> inst_type == S_TYPE;
        (opcode == OP_BRANCH) -> inst_type == B_TYPE;
        (opcode == OP_LUI || opcode == OP_AUIPC) -> inst_type == U_TYPE;
        (opcode == OP_JAL) -> inst_type == J_TYPE;
        (opcode == OP_SYSTEM || opcode == OP_FENCE) -> inst_type == SYSTEM;
    }
    
    // Memory size valid for loads/stores
    constraint mem_size_c {
        if (mem_read || mem_write) {
            mem_size inside {[0:3]};  // byte, half, word, dword
        }
    }
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "riscv_transaction");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Post-randomize: Build instruction encoding
    //==========================================================================
    function void post_randomize();
        // Assemble instruction based on type
        case (inst_type)
            R_TYPE: instruction = {funct7, rs2, rs1, funct3, rd, opcode};
            I_TYPE: instruction = {imm[11:0], rs1, funct3, rd, opcode};
            S_TYPE: instruction = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
            B_TYPE: instruction = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
            U_TYPE: instruction = {imm[31:12], rd, opcode};
            J_TYPE: instruction = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
            default: instruction = 32'h00000013;  // NOP (ADDI x0, x0, 0)
        endcase
    endfunction
    
    //==========================================================================
    // Helper Functions
    //==========================================================================
    
    // Check if this is a load instruction
    function bit is_load();
        return (opcode == OP_LOAD);
    endfunction
    
    // Check if this is a store instruction
    function bit is_store();
        return (opcode == OP_STORE);
    endfunction
    
    // Check if uses immediate
    function bit uses_immediate();
        return (inst_type == I_TYPE || inst_type == S_TYPE || 
                inst_type == B_TYPE || inst_type == U_TYPE || inst_type == J_TYPE);
    endfunction
    
    // Custom convert2string for better display
    function string convert2string();
        string s;
        s = $sformatf("\n=== RISC-V Transaction ===\n");
        s = {s, $sformatf("PC: 0x%016x\n", pc)};
        s = {s, $sformatf("Instruction: 0x%08x\n", instruction)};
        s = {s, $sformatf("Opcode: 0x%02x, Type: %s\n", opcode, inst_type.name())};
        s = {s, $sformatf("rd=%0d, rs1=%0d, rs2=%0d\n", rd, rs1, rs2)};
        if (uses_immediate())
            s = {s, $sformatf("Immediate: 0x%016x\n", imm)};
        return s;
    endfunction
    
endclass

`endif // RISCV_TRANSACTION_SV
