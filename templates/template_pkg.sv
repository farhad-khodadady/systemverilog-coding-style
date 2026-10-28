// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_pkg.sv
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <Types, constants and functions shared by the modules and interfaces of this IP.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Import with "import template_pkg::*;" in the header of every module that uses it.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - <Planned work for this file, or "None".>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

`ifndef TEMPLATE_PKG_SV
`define TEMPLATE_PKG_SV

package template_pkg;

    // ===============================================================================================================================================
    // Constants
    // ===============================================================================================================================================
    // Packages hold constants as localparam: a "parameter" in a package cannot be overridden anyway.
    localparam int unsigned BYTE_WIDTH = 8;
    localparam int unsigned WORD_WIDTH = 32;
    localparam int unsigned WORD_BYTES = WORD_WIDTH / BYTE_WIDTH;

    // ===============================================================================================================================================
    // Type definitions
    // ===============================================================================================================================================
    typedef logic [WORD_WIDTH-1:0] word_t;

    // Enumerations always have an explicit base type and end in _e.
    typedef enum logic [1:0] {
        CMD_NOP   = 2'd0,
        CMD_READ  = 2'd1,
        CMD_WRITE = 2'd2
    } cmd_e;

    // Fields that travel together are grouped in a packed struct and passed through a single port.
    typedef struct packed {
        cmd_e  cmd;
        word_t addr;
        word_t data;
    } request_t;

    // Packed union: the same 32 bits seen as one word or as individual bytes.
    typedef union packed {
        word_t                                 word;
        logic [WORD_BYTES-1:0][BYTE_WIDTH-1:0] bytes;
    } word_view_t;

    // ===============================================================================================================================================
    // Functions
    // ===============================================================================================================================================
    // Reverses the byte order of a word (big-endian <-> little-endian).
    function automatic word_t swap_bytes(input word_t value);
        word_view_t in_view;
        word_view_t out_view;
        in_view.word = value;
        for (int unsigned i = 0; i < WORD_BYTES; i++) begin
            out_view.bytes[i] = in_view.bytes[WORD_BYTES-1-i];
        end
        return out_view.word;
    endfunction : swap_bytes

endpackage : template_pkg

`endif  // TEMPLATE_PKG_SV
