//==============================================================================
// File: riscv_l1_cache.sv
// Description: L1 Data Cache - 16KB, 4-way Set Associative
// Purpose: Single-cycle hit latency for 2 GHz operation
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
// Configuration: 16KB total, 4-way, 64B line, 64 sets
//==============================================================================

module riscv_l1_cache (
    input  logic        clk,
    input  logic        rst_n,
    // CPU Interface
    input  logic [31:0] addr,
    input  logic        read,
    input  logic        write,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,             // NO RESET - Data path
    output logic        ready,             // WITH RESET - Control path
    // L2 Cache Interface
    output logic [31:0] l2_addr,
    output logic        l2_read,
    output logic        l2_write,
    output logic [31:0] l2_wdata,
    input  logic [31:0] l2_rdata,
    input  logic        l2_ready
);

    // Cache parameters
    localparam CACHE_SIZE  = 16384;        // 16KB
    localparam LINE_SIZE   = 64;           // 64 bytes per line
    localparam NUM_WAYS    = 4;            // 4-way set associative
    localparam NUM_SETS    = 64;           // 64 sets
    localparam TAG_WIDTH   = 20;           // Tag bits
    localparam INDEX_WIDTH = 6;            // Set index bits
    localparam OFFSET_WIDTH = 6;           // Byte offset bits

    // Address breakdown
    logic [TAG_WIDTH-1:0]    tag;
    logic [INDEX_WIDTH-1:0]  index;
    logic [OFFSET_WIDTH-1:0] offset;

    assign tag    = addr[31:31-TAG_WIDTH+1];
    assign index  = addr[31-TAG_WIDTH:OFFSET_WIDTH];
    assign offset = addr[OFFSET_WIDTH-1:0];

    // Cache arrays (simplified - storing only 32-bit words)
    logic [31:0]           data_array   [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [TAG_WIDTH-1:0]  tag_array    [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic                  valid_array  [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [NUM_WAYS-1:0]   hit_way;
    logic                  cache_hit;
    logic [1:0]            lru_counter  [NUM_SETS-1:0];  // Simple LRU

//==============================================================================
// Cache Lookup Logic
//==============================================================================
    always_comb begin
        cache_hit = 1'b0;
        hit_way = '0;
        for (int i = 0; i < NUM_WAYS; i++) begin
            if (valid_array[index][i] && (tag_array[index][i] == tag)) begin
                cache_hit = 1'b1;
                hit_way[i] = 1'b1;
            end
        end
    end

//==============================================================================
// Read Operation
//==============================================================================
    always_ff @(posedge clk) begin
        if (read && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i])
                    rdata <= data_array[index][i];
            end
        end else if (read && l2_ready) begin
            rdata <= l2_rdata;
        end
    end

//==============================================================================
// Write Operation
//==============================================================================
    always_ff @(posedge clk) begin
        if (write && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i])
                    data_array[index][i] <= wdata;
            end
        end else if (write && l2_ready) begin
            // Allocate on write miss
            data_array[index][lru_counter[index]] <= wdata;
            tag_array[index][lru_counter[index]]  <= tag;
            valid_array[index][lru_counter[index]] <= 1'b1;
        end
    end

//==============================================================================
// Valid Array and LRU Management (WITH RESET - Control path)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < NUM_WAYS; j++) begin
                    valid_array[i][j] <= 1'b0;
                end
                lru_counter[i] <= 2'b00;
            end
            ready <= 1'b0;
        end else begin
            if (cache_hit)
                ready <= 1'b1;
            else if (l2_ready)
                ready <= 1'b1;
            else
                ready <= 1'b0;
            
            // Update LRU on access
            if ((read || write) && !cache_hit)
                lru_counter[index] <= lru_counter[index] + 1;
        end
    end

//==============================================================================
// L2 Interface
//==============================================================================
    assign l2_addr  = addr;
    assign l2_read  = read && !cache_hit;
    assign l2_write = write && !cache_hit;
    assign l2_wdata = wdata;

endmodule
