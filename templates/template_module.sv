// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_module.sv
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <One or two sentences: what this module does and where it is used.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Example behaviour: while the child FSM is busy, valid input words are byte-swapped and registered.
//   - References: <specification, standard or document this module implements>.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - Replace the example logic; keep the section layout.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

// ===================================================================================================================================================
// Include files (macros only; resolved through the include path)
// ===================================================================================================================================================
`include "template_macros.svh"

`default_nettype none

module template_module
    // Imported here, not at file scope: visible to the parameter and port lists, local to this module.
    import template_pkg::*;
#(
    parameter int unsigned RUN_CYCLES = 8  // Cycles the input window stays open after start_i
) (
    // Clock and reset
    input  logic  clk,      // Clock
    input  logic  rst_n,    // Asynchronous reset, active low
    // Control
    input  logic  start_i,  // Open the input window
    output logic  busy_o,   // Input window is open
    output logic  done_o,   // One-cycle pulse when the window closes
    // Data input
    input  logic  valid_i,  // data_i is valid
    input  word_t data_i,   // Input word
    // Data output
    output logic  valid_o,  // data_o is valid
    output word_t data_o    // Byte-swapped input word
);

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Local parameters
    // ===============================================================================================================================================
    localparam int unsigned FSM_RUN_CYCLES = `TPL_MAX(RUN_CYCLES, 1);

    // ===============================================================================================================================================
    // Signal declarations (registers, nets between blocks, signals read in more than one block)
    // ===============================================================================================================================================
    logic  fsm_busy;
    logic  capture;
    logic  valid_q;
    word_t data_q;
    word_t data_d;

    // ===============================================================================================================================================
    // Sub-module instances
    // ===============================================================================================================================================
    template_fsm #(
        .RUN_CYCLES(FSM_RUN_CYCLES)
    ) u_template_fsm (
        .clk    (clk),
        .rst_n  (rst_n),
        .start_i(start_i),
        .busy_o (fsm_busy),
        .done_o (done_o)
    );

    // ===============================================================================================================================================
    // Data path: next-state logic and register
    // ===============================================================================================================================================
    // TODO: Replace the example data path (byte swap while the FSM is busy).
    assign capture = valid_i && fsm_busy;

    always_comb begin
        data_d = data_q;
        if (capture) begin
            data_d = swap_bytes(data_i);
        end
    end

    // Data register: no reset. It is only observed when valid_q is set.
    always_ff @(posedge clk) begin
        data_q <= data_d;
    end

    // Control register: reset, because its value is observed right after reset.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_q <= 1'b0;
        end else begin
            valid_q <= capture;
        end
    end

    // ===============================================================================================================================================
    // Outputs
    // ===============================================================================================================================================
    assign busy_o  = fsm_busy;
    assign valid_o = valid_q;
    assign data_o  = data_q;

endmodule : template_module

`default_nettype wire
