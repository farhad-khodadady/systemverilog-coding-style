// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_if.sv
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <Valid/ready streaming interface: one modport per role plus protocol assertions.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Signals inside an interface carry no _i/_o suffix: the direction depends on the modport.
//   - Keep plain ports (not interfaces) on the FPGA/ASIC top level and on IP-packager boundaries.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - <Planned work for this file, or "None".>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

`default_nettype none

interface template_if #(
    parameter int unsigned DATA_WIDTH = 32  // Payload width in bits
) (
    input wire clk,   // Clock shared by source and sink
    input wire rst_n  // Asynchronous reset, active low
);

    timeunit 1ns; timeprecision 1ps;

    // ===============================================================================================================================================
    // Signals
    // ===============================================================================================================================================
    logic                  valid;  // Source has data
    logic                  ready;  // Sink accepts data
    logic [DATA_WIDTH-1:0] data;  // Payload, stable while valid && !ready

    // ===============================================================================================================================================
    // Modports (named after the role of the connected module)
    // ===============================================================================================================================================
    modport source(input clk, rst_n, ready, output valid, data);
    modport sink(input clk, rst_n, valid, data, output ready);
    modport monitor(input clk, rst_n, valid, ready, data);

    // ===============================================================================================================================================
    // Protocol assertions (simulation and formal only)
    // ===============================================================================================================================================
`ifndef SYNTHESIS
    // Once valid is raised, valid and data must hold until the transfer completes.
    assert_valid_stable :
    assert property (@(posedge clk) disable iff (!rst_n) (valid && !ready) |=> (valid && $stable(data)))
    else begin
        $error("template_if: valid dropped or data changed before ready");
    end
`endif  // SYNTHESIS

endinterface : template_if

`default_nettype wire
