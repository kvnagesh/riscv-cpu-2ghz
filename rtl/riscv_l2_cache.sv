//==============================================================================
// Copyright (c) 2025 Nagesh Vishnumurthy
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//==============================================================================

//==============================================================================
// File: riscv_l2_cache.sv
// Description: L2 Unified Cache - 64KB, 8-way Set Associative
// Purpose: Secondary cache for both instruction and data
// Critical Path: < 500ps @ 7nm (for 2 GHz operation)
// Configuration: 64KB total, 8-way, 64B line, 128 sets
//==============================================================================

module riscv_l2_cache (
    input  logic        clk,
    input  logic        rst_n,
    // L1 Cache Interface
    input  logic [31:0] l1_addr,
    input  logic        l1_read,
    input  logic        l1_write,
    input  logic [31:0] l1_wdata,
    output logic [31:0] l1_rdata,          // NO RESET - Data path
    output logic        l1_ready,          // WITH RESET - Control path
    // Memory Interface
    output logic [31:0] mem_addr,
    output logic        mem_read,
    output logic        mem_write,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready
);

    // Cache parameters
    localparam CACHE_SIZE  = 65536;        // 64KB
    localparam LINE_SIZE   = 64;           // 64 bytes per line
    localparam NUM_WAYS    = 8;            // 8-way set associative
    localparam NUM_SETS    = 128;          // 128 sets
    localparam TAG_WIDTH   = 19;           // Tag bits
    localparam INDEX_WIDTH = 7;            // Set index bits
    localparam OFFSET_WIDTH = 6;           // Byte offset bits

    // Address breakdown
    logic [TAG_WIDTH-1:0]    tag;
    logic [INDEX_WIDTH-1:0]  index;
    logic [OFFSET_WIDTH-1:0] offset;

    assign tag    = l1_addr[31:31-TAG_WIDTH+1];
    assign index  = l1_addr[31-TAG_WIDTH:OFFSET_WIDTH];
    assign offset = l1_addr[OFFSET_WIDTH-1:0];

    // Cache arrays (simplified - storing only 32-bit words)
    logic [31:0]           data_array   [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [TAG_WIDTH-1:0]  tag_array    [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic                  valid_array  [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic                  dirty_array  [NUM_SETS-1:0][NUM_WAYS-1:0];
    logic [NUM_WAYS-1:0]   hit_way;
    logic                  cache_hit;
    logic [2:0]            lru_counter  [NUM_SETS-1:0];  // Simple LRU (3 bits for 8-way)

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
        if (l1_read && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i])
                    l1_rdata <= data_array[index][i];
            end
        end else if (l1_read && mem_ready) begin
            l1_rdata <= mem_rdata;
        end
    end

//==============================================================================
// Write Operation
//==============================================================================
    always_ff @(posedge clk) begin
        if (l1_write && cache_hit) begin
            for (int i = 0; i < NUM_WAYS; i++) begin
                if (hit_way[i]) begin
                    data_array[index][i] <= l1_wdata;
                    dirty_array[index][i] <= 1'b1;     // Mark as dirty
                end
            end
        end else if (l1_write && mem_ready) begin
            // Allocate on write miss
            data_array[index][lru_counter[index]] <= l1_wdata;
            tag_array[index][lru_counter[index]]  <= tag;
            valid_array[index][lru_counter[index]] <= 1'b1;
            dirty_array[index][lru_counter[index]] <= 1'b1;
        end
    end

//==============================================================================
// Valid/Dirty Array and LRU Management (WITH RESET - Control path)
//==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_SETS; i++) begin
                for (int j = 0; j < NUM_WAYS; j++) begin
                    valid_array[i][j] <= 1'b0;
                    dirty_array[i][j] <= 1'b0;
                end
                lru_counter[i] <= 3'b000;
            end
            l1_ready <= 1'b0;
        end else begin
            if (cache_hit)
                l1_ready <= 1'b1;
            else if (mem_ready)
                l1_ready <= 1'b1;
            else
                l1_ready <= 1'b0;
            
            // Update LRU on access
            if ((l1_read || l1_write) && !cache_hit)
                lru_counter[index] <= lru_counter[index] + 1;
        end
    end

//==============================================================================
// Memory Interface
//==============================================================================
    assign mem_addr  = l1_addr;
    assign mem_read  = l1_read && !cache_hit;
    assign mem_write = l1_write && !cache_hit;
    assign mem_wdata = l1_wdata;

endmodule
