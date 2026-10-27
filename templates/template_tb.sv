// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_tb.sv
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <Self-checking testbench for template_module.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Ends with exactly one "TEST PASSED" or "TEST FAILED" line so scripts and CI can gate on it.
//   - Plusargs: +seed=<n> reseeds the random stimulus, +dump=1 writes template_tb.vcd.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - <Planned work for this file, or "None".>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

`default_nettype none

module template_tb
    import template_pkg::*;
();

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Parameters
    // ===============================================================================================================================================
    localparam int unsigned CLK_HALF_PERIOD = 5;  // ns, 100 MHz clock
    localparam int unsigned RUN_CYCLES = 8;
    localparam int unsigned NUM_RUNS = 20;
    localparam int unsigned TIMEOUT_CYCLES = 10_000;

    // ===============================================================================================================================================
    // Signals
    // ===============================================================================================================================================
    logic  clk;
    logic  rst_n;
    logic  start;
    logic  busy;
    logic  done;
    logic  in_valid;
    word_t in_data;
    logic  out_valid;
    word_t out_data;

    // ===============================================================================================================================================
    // Verification state (2-state types: X has no meaning here)
    // ===============================================================================================================================================
    word_t       expected_queue  [$];
    int unsigned num_checked = 0;
    int unsigned num_errors = 0;
    int unsigned seed = 1;
    int unsigned dump = 0;

    // ===============================================================================================================================================
    // Design under test
    // ===============================================================================================================================================
    template_module #(
        .RUN_CYCLES(RUN_CYCLES)
    ) u_dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .start_i(start),
        .busy_o (busy),
        .done_o (done),
        .valid_i(in_valid),
        .data_i (in_data),
        .valid_o(out_valid),
        .data_o (out_data)
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
    // Reference model (written independently of the DUT; do not reuse DUT functions here)
    // ===============================================================================================================================================
    function automatic word_t model_swap(input word_t value);
        return {value[7:0], value[15:8], value[23:16], value[31:24]};
    endfunction : model_swap

    // ===============================================================================================================================================
    // Scoreboard: inputs and outputs are sampled on the active clock edge
    // ===============================================================================================================================================
    always @(posedge clk) begin
        if (rst_n) begin
            if (out_valid) begin
                if (expected_queue.size() == 0) begin
                    num_errors++;
                    $error("Unexpected output 0x%08h", out_data);
                end else begin
                    word_t expected;
                    expected = expected_queue.pop_front();
                    num_checked++;
                    if (out_data !== expected) begin
                        num_errors++;
                        $error("Mismatch: got 0x%08h, expected 0x%08h", out_data, expected);
                    end
                end
            end
            if (in_valid && busy) begin
                expected_queue.push_back(model_swap(in_data));
            end
        end
    end

    // ===============================================================================================================================================
    // Stimulus: inputs change on the inactive (falling) clock edge
    // ===============================================================================================================================================
    task automatic run_once();
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        while (!done) begin
            in_valid = 1'($urandom_range(1, 0));
            in_data  = $urandom();
            @(negedge clk);
        end
        in_valid = 1'b0;
    endtask : run_once

    // ===============================================================================================================================================
    // Test sequence
    // ===============================================================================================================================================
    initial begin
        if ($value$plusargs("dump=%d", dump) && dump != 0) begin
            $dumpfile("template_tb.vcd");
            $dumpvars(0, template_tb);
        end
        if ($value$plusargs("seed=%d", seed)) begin
            $display("Using seed %0d", seed);
        end
        void'($urandom(seed));

        start    = 1'b0;
        in_valid = 1'b0;
        in_data  = '0;
        apply_reset(5);

        repeat (NUM_RUNS) begin
            run_once();
        end
        repeat (2) @(negedge clk);

        if (expected_queue.size() != 0) begin
            num_errors++;
            $error("%0d expected outputs never appeared", expected_queue.size());
        end
        if (num_errors == 0 && num_checked > 0) begin
            $display("TEST PASSED (%0d words checked)", num_checked);
        end else begin
            $display("TEST FAILED (%0d errors, %0d words checked)", num_errors, num_checked);
        end
        $finish;
    end

    // Watchdog: a hung test fails instead of hanging the regression.
    initial begin
        repeat (TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1, "TEST FAILED (timeout after %0d cycles)", TIMEOUT_CYCLES);
    end

endmodule : template_tb

`default_nettype wire
