// ===================================================================================================================================================
// Copyright (c) 2026 Farhad Khodadady
// SPDX-License-Identifier: MIT
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : sync_fifo_tb.sv
// Author      : Farhad Khodadady
// Created     : 2026-10-27
// Description : Self-checking testbench for sync_fifo: random valid/ready traffic against a queue
//               reference model, with checks on data, ordering and every status output.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    2026-10-27  Farhad Khodadady  Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Traffic alternates between write-heavy and read-heavy phases so the FIFO reaches full and
//     empty; the test fails if either state was never reached.
//   - Ends with exactly one "TEST PASSED" or "TEST FAILED" line so scripts and CI can gate on it.
//   - Plusargs: +seed=<n> reseeds the random stimulus, +dump=1 writes sync_fifo_tb.vcd.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - None.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - None.
// ===================================================================================================================================================

`default_nettype none

module sync_fifo_tb;

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Parameters
    // ===============================================================================================================================================
    localparam int unsigned DATA_WIDTH = 8;
    localparam int unsigned DEPTH = 5;  // Not a power of two: exercises pointer wrap-around
    localparam int unsigned LEVEL_WIDTH = $clog2(DEPTH + 1);
    localparam int unsigned CLK_HALF_PERIOD = 5;  // ns, 100 MHz clock
    localparam int unsigned NUM_WORDS = 2_000;
    localparam int unsigned PHASE_CYCLES = 64;
    localparam int unsigned TIMEOUT_CYCLES = 100_000;

    // ===============================================================================================================================================
    // Signals
    // ===============================================================================================================================================
    logic                   clk;
    logic                   rst_n;
    logic                   wr_valid;
    logic                   wr_ready;
    logic [ DATA_WIDTH-1:0] wr_data;
    logic                   rd_valid;
    logic                   rd_ready;
    logic [ DATA_WIDTH-1:0] rd_data;
    logic [LEVEL_WIDTH-1:0] level;

    // ===============================================================================================================================================
    // Verification state (2-state types: X has no meaning here)
    // ===============================================================================================================================================
    bit          [DATA_WIDTH-1:0] model_queue          [$];
    int unsigned                  num_written = 0;
    int unsigned                  num_read = 0;
    int unsigned                  num_errors = 0;
    int unsigned                  num_full_cycles = 0;
    int unsigned                  num_empty_cycles = 0;
    int unsigned                  seed = 1;
    int unsigned                  dump = 0;

    // ===============================================================================================================================================
    // Design under test
    // ===============================================================================================================================================
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) u_dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_valid_i(wr_valid),
        .wr_ready_o(wr_ready),
        .wr_data_i (wr_data),
        .rd_valid_o(rd_valid),
        .rd_ready_i(rd_ready),
        .rd_data_o (rd_data),
        .level_o   (level)
    );

    // ===============================================================================================================================================
    // Clock & reset
    // ===============================================================================================================================================
    initial begin
        clk = 1'b0;
        forever begin
            #(CLK_HALF_PERIOD) clk = ~clk;
        end
    end

    task automatic apply_reset(input int unsigned cycles);
        rst_n = 1'b0;
        repeat (cycles) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
    endtask : apply_reset

    // ===============================================================================================================================================
    // Helpers
    // ===============================================================================================================================================
    // Returns 1 with the given probability in percent.
    function automatic bit chance(input int unsigned percent);
        return $urandom_range(99, 0) < percent;
    endfunction : chance

    function automatic void report_error(input string message);
        num_errors++;
        $error("%s", message);
    endfunction : report_error

    // ===============================================================================================================================================
    // Scoreboard: compares the DUT with the reference model on every active clock edge
    // ===============================================================================================================================================
    always @(posedge clk) begin
        if (rst_n) begin
            // Status outputs against the model (both still hold their pre-edge state here).
            if (wr_ready !== (model_queue.size() < DEPTH)) begin
                report_error($sformatf("wr_ready=%0d with %0d words stored", wr_ready, model_queue.size()));
            end
            if (rd_valid !== (model_queue.size() > 0)) begin
                report_error($sformatf("rd_valid=%0d with %0d words stored", rd_valid, model_queue.size()));
            end
            if (level !== LEVEL_WIDTH'(model_queue.size())) begin
                report_error($sformatf("level=%0d, expected %0d", level, model_queue.size()));
            end

            // Coverage of the corner states this test must reach.
            if (model_queue.size() == DEPTH) begin
                num_full_cycles++;
            end
            if (model_queue.size() == 0) begin
                num_empty_cycles++;
            end

            // Read before write: a word written in this cycle cannot be read in the same cycle.
            if (rd_valid && rd_ready) begin
                bit [DATA_WIDTH-1:0] expected;
                expected = model_queue.pop_front();
                num_read++;
                if (rd_data !== expected) begin
                    report_error($sformatf("read #%0d: got 0x%02h, expected 0x%02h", num_read, rd_data, expected));
                end
            end
            if (wr_valid && wr_ready) begin
                model_queue.push_back(wr_data);
                num_written++;
            end
        end
    end

    // ===============================================================================================================================================
    // Stimulus: inputs change on the inactive (falling) clock edge
    // ===============================================================================================================================================
    task automatic run_traffic(input int unsigned num_words);
        int unsigned cycle;
        bit          wr_accepted;
        bit          write_heavy;
        cycle = 0;
        while (num_written < num_words) begin
            @(posedge clk);
            wr_accepted = wr_valid && wr_ready;
            @(negedge clk);
            write_heavy = ((cycle / PHASE_CYCLES) % 2) == 0;
            // Valid/ready rule: once raised, wr_valid and wr_data hold until the word is accepted.
            if (!wr_valid || wr_accepted) begin
                wr_valid = chance(write_heavy ? 90 : 30);
                wr_data  = DATA_WIDTH'($urandom());
            end
            rd_ready = chance(write_heavy ? 30 : 90);
            cycle++;
        end
        // Let a pending write complete instead of withdrawing it.
        rd_ready = 1'b1;
        while (wr_valid) begin
            @(posedge clk);
            wr_accepted = wr_valid && wr_ready;
            @(negedge clk);
            if (wr_accepted) begin
                wr_valid = 1'b0;
            end
        end
    endtask : run_traffic

    task automatic drain();
        rd_ready = 1'b1;
        while (rd_valid) begin
            @(negedge clk);
        end
        rd_ready = 1'b0;
    endtask : drain

    // ===============================================================================================================================================
    // Test sequence
    // ===============================================================================================================================================
    initial begin
        if ($value$plusargs("dump=%d", dump) && dump != 0) begin
            $dumpfile("sync_fifo_tb.vcd");
            $dumpvars(0, sync_fifo_tb);
        end
        if ($value$plusargs("seed=%d", seed)) begin
            $display("Using seed %0d", seed);
        end
        void'($urandom(seed));

        wr_valid = 1'b0;
        wr_data  = '0;
        rd_ready = 1'b0;
        apply_reset(5);

        run_traffic(NUM_WORDS);
        drain();
        repeat (2) @(negedge clk);

        if (num_read != num_written) begin
            report_error($sformatf("%0d words written but %0d read", num_written, num_read));
        end
        if (num_full_cycles == 0 || num_empty_cycles == 0) begin
            report_error($sformatf("coverage hole: full=%0d empty=%0d cycles", num_full_cycles, num_empty_cycles));
        end

        if (num_errors == 0) begin
            $display("TEST PASSED (%0d words, full %0d cycles, empty %0d cycles)", num_read, num_full_cycles, num_empty_cycles);
        end else begin
            $display("TEST FAILED (%0d errors)", num_errors);
        end
        $finish;
    end

    // Watchdog: a hung test fails instead of hanging the regression.
    initial begin
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "TEST FAILED (timeout after %0d cycles)", TIMEOUT_CYCLES);
    end

endmodule : sync_fifo_tb

`default_nettype wire
