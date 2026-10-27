// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_fsm.sv
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <Finite state machine template: enumerated state type, one always_ff for the state
//               register and one always_comb for next-state and output logic.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Example behaviour: start_i launches a run of RUN_CYCLES cycles, then done_o pulses for one cycle.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - Replace the example states and transitions with the real ones.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

`default_nettype none

module template_fsm #(
    parameter int unsigned RUN_CYCLES = 4  // Number of cycles spent in RUN (>= 1)
) (
    input  logic clk,      // Clock
    input  logic rst_n,    // Asynchronous reset, active low
    input  logic start_i,  // Start a run (ignored while busy)
    output logic busy_o,   // High while a run is in progress
    output logic done_o    // One-cycle pulse when a run completes
);

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Local parameters & types
    // ===============================================================================================================================================
    localparam int unsigned CNT_WIDTH = (RUN_CYCLES > 1) ? $clog2(RUN_CYCLES) : 1;
    localparam logic [CNT_WIDTH-1:0] CNT_LAST = CNT_WIDTH'(RUN_CYCLES - 1);

    // Explicit base type and explicit encodings: the state register width is fixed and the values seen in waveforms and netlists are known.
    // TODO: Replace the example states with the real ones.
    typedef enum logic [1:0] {
        IDLE = 2'd0,
        RUN  = 2'd1,
        DONE = 2'd2
    } state_e;

    // ===============================================================================================================================================
    // Signal declarations
    // ===============================================================================================================================================
    state_e                 state_q;
    state_e                 state_d;
    logic   [CNT_WIDTH-1:0] cnt_q;
    logic   [CNT_WIDTH-1:0] cnt_d;

    // ===============================================================================================================================================
    // Next-state and output logic
    // ===============================================================================================================================================
    always_comb begin
        // Default assignments: every output of the block is assigned on every path (no latches).
        state_d = state_q;
        cnt_d   = cnt_q;
        busy_o  = 1'b0;
        done_o  = 1'b0;

        // TODO: Replace the example transitions and outputs.
        unique case (state_q)
            IDLE: begin
                cnt_d = '0;
                if (start_i) begin
                    state_d = RUN;
                end
            end

            RUN: begin
                busy_o = 1'b1;
                cnt_d  = cnt_q + 1'b1;
                if (cnt_q == CNT_LAST) begin
                    state_d = DONE;
                end
            end

            DONE: begin
                done_o  = 1'b1;
                state_d = IDLE;
            end

            // Unused encoding: recover to a known state instead of assigning X.
            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // ===============================================================================================================================================
    // State register
    // ===============================================================================================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            cnt_q   <= '0;
        end else begin
            state_q <= state_d;
            cnt_q   <= cnt_d;
        end
    end

endmodule : template_fsm

`default_nettype wire
