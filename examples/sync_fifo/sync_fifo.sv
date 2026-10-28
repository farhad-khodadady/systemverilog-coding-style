// ===================================================================================================================================================
// Copyright (c) 2026 Farhad Khodadady
// SPDX-License-Identifier: MIT
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : sync_fifo.sv
// Author      : Farhad Khodadady
// Created     : 2026-10-27
// Description : Single-clock FIFO with valid/ready handshakes on both sides and show-ahead read
//               data. Any DEPTH >= 1 is supported (not only powers of two).
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    2026-10-27  Farhad Khodadady  Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - A write and a read in the same cycle are both accepted, except when the FIFO is full: then
//     wr_ready_o is low for that cycle (simple timing, no combinational path from rd_ready_i).
//   - The storage array has no reset; it maps to distributed RAM or flip-flops.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - None.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - None.
// ===================================================================================================================================================

`default_nettype none

module sync_fifo #(
    parameter int unsigned DATA_WIDTH = 8,  // Width of one entry in bits (>= 1)
    parameter int unsigned DEPTH      = 16  // Number of entries (>= 1)
) (
    input  wire                        clk,
    input  wire                        rst_n,
    // Write side
    input  wire                        wr_valid_i,
    output logic                       wr_ready_o,
    input  wire  [     DATA_WIDTH-1:0] wr_data_i,
    // Read side
    output logic                       rd_valid_o,
    input  wire                        rd_ready_i,
    output logic [     DATA_WIDTH-1:0] rd_data_o,
    // Number of words stored
    output logic [$clog2(DEPTH+1)-1:0] level_o
);

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Local parameters & types
    // ===============================================================================================================================================
    localparam int unsigned PTR_WIDTH   = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    localparam int unsigned LEVEL_WIDTH = $clog2(DEPTH + 1);

    typedef logic [PTR_WIDTH-1:0] ptr_t;
    typedef logic [LEVEL_WIDTH-1:0] level_t;

    localparam ptr_t   LAST_PTR   = ptr_t'(DEPTH - 1);
    localparam level_t FULL_LEVEL = level_t'(DEPTH);

    // ===============================================================================================================================================
    // Signal declarations
    // ===============================================================================================================================================
    logic   [DATA_WIDTH-1:0] mem_q    [DEPTH];
    ptr_t                    wr_ptr_q;
    ptr_t                    wr_ptr_d;
    ptr_t                    rd_ptr_q;
    ptr_t                    rd_ptr_d;
    level_t                  level_q;
    level_t                  level_d;
    logic                    wr_en;
    logic                    rd_en;

    // ===============================================================================================================================================
    // Functions
    // ===============================================================================================================================================
    // Pointer increment that wraps at DEPTH, so non-power-of-two depths work.
    function automatic ptr_t next_ptr(input ptr_t ptr);
        return (ptr == LAST_PTR) ? '0 : ptr + 1'b1;
    endfunction : next_ptr

    // ===============================================================================================================================================
    // Handshakes
    // ===============================================================================================================================================
    assign wr_ready_o = (level_q != FULL_LEVEL);
    assign rd_valid_o = (level_q != '0);
    assign wr_en      = wr_valid_i && wr_ready_o;
    assign rd_en      = rd_valid_o && rd_ready_i;

    // ===============================================================================================================================================
    // Control path: next-state logic and registers
    // ===============================================================================================================================================
    always_comb begin
        wr_ptr_d = wr_ptr_q;
        rd_ptr_d = rd_ptr_q;
        level_d  = level_q;

        if (wr_en) begin
            wr_ptr_d = next_ptr(wr_ptr_q);
        end
        if (rd_en) begin
            rd_ptr_d = next_ptr(rd_ptr_q);
        end

        // A write and a read in the same cycle leave the level unchanged.
        if (wr_en && !rd_en) begin
            level_d = level_q + 1'b1;
        end else if (rd_en && !wr_en) begin
            level_d = level_q - 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_q <= '0;
            rd_ptr_q <= '0;
            level_q  <= '0;
        end else begin
            wr_ptr_q <= wr_ptr_d;
            rd_ptr_q <= rd_ptr_d;
            level_q  <= level_d;
        end
    end

    // ===============================================================================================================================================
    // Storage (data path: no reset)
    // ===============================================================================================================================================
    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem_q[wr_ptr_q] <= wr_data_i;
        end
    end

    // ===============================================================================================================================================
    // Outputs
    // ===============================================================================================================================================
    assign rd_data_o = mem_q[rd_ptr_q];
    assign level_o   = level_q;

    // ===============================================================================================================================================
    // Parameter checks (simulation only)
    // ===============================================================================================================================================
`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1 || DEPTH < 1) begin
            $fatal(1, "sync_fifo: DATA_WIDTH and DEPTH must be >= 1 (got %0d, %0d)", DATA_WIDTH, DEPTH);
        end
    end
`endif  // SYNTHESIS

endmodule : sync_fifo

`default_nettype wire
