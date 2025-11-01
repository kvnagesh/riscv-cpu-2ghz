//==============================================================================
// File: riscv_l1_cache_optimized.sv
// Description: Optimized L1 Cache with Hit-Under-Miss and Alignment
// Improvements: Non-blocking cache, 64-bit aligned access, write buffer
//==============================================================================

module riscv_l1_cache_optimized (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [63:0]  addr,          // 64-bit address
    input  logic         read,
    input  logic         write,
    input  logic [63:0]  wdata,         // 64-bit write data
    output logic [63:0]  rdata,         // 64-bit read data
    output logic         ready,
    output logic [63:0]  l2_addr,
    output logic         l2_read,
    output logic         l2_write,
    output logic [63:0]  l2_wdata,
    input  logic [63:0]  l2_rdata,
    input  logic         l2_ready
);

    localparam NUM_SETS = 64;
    localparam NUM_WAYS = 4;
    localparam TAG_WIDTH = 20;
    localparam INDEX_WIDTH = 6;
    
    // 64-bit aligned address breakdown
    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    assign tag = addr[63:63-TAG_WIDTH+1];
    assign index = addr[INDEX_WIDTH+2:3];  // 64-bit (8-byte) alignment
    
    logic [63:0] data_array [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [TAG_WIDTH-1:0] tag_array [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic valid_array [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [1:0] lru_counter [NUM_SETS-1:0];
    
    // Hit-under-miss support: Miss Status Handling Registers (MSHR)
    logic miss_pending;
    logic [63:0] miss_addr;
    
    // Write buffer for non-blocking writes
    logic [63:0] write_buffer_addr;
    logic [63:0] write_buffer_data;
    logic write_buffer_valid;
    
    logic [NUM_WAYS-1:0] hit_way;
    logic cache_hit;
    
    // Cache hit detection
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
    
    // Read with hit-under-miss: can serve hits while miss pending
    always_ff @(posedge clk) begin
        if (read && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i])
                    rdata <= data_array[index][i];
            end
        end else if (read && !miss_pending && l2_ready) begin
            rdata <= l2_rdata;
        end
    end
    
    // Write with write buffer
    always_ff @(posedge clk) begin
        if (write && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i])
                    data_array[index][i] <= wdata;
            end
        end else if (write && !cache_hit) begin
            // Buffer write for later
            write_buffer_addr <= addr;
            write_buffer_data <= wdata;
            write_buffer_valid <= 1'b1;
        end
    end
    
    // Control path with reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < NUM_WAYS; j++) begin
                    valid_array[i][j] <= 1'b0;
                end
                lru_counter[i] <= 2'b00;
            end
            ready <= 1'b0;
            miss_pending <= 1'b0;
            write_buffer_valid <= 1'b0;
        end else begin
            ready <= cache_hit || (l2_ready && !miss_pending);
            if ((read || write) && !cache_hit && !miss_pending) begin
                miss_pending <= 1'b1;
                miss_addr <= addr;
            end else if (miss_pending && l2_ready) begin
                miss_pending <= 1'b0;
                data_array[index][lru_counter[index]] <= l2_rdata;
                tag_array[index][lru_counter[index]] <= tag;
                valid_array[index][lru_counter[index]] <= 1'b1;
                lru_counter[index] <= lru_counter[index] + 1;
            end
        end
    end
    
    assign l2_addr = miss_pending ? miss_addr : addr;
    assign l2_read = read && !cache_hit && !miss_pending;
    assign l2_write = write && !cache_hit;
    assign l2_wdata = wdata;

endmodule
