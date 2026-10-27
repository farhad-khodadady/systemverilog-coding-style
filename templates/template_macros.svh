// ===================================================================================================================================================
// Copyright (c) <YEAR> <COPYRIGHT HOLDER>
// SPDX-License-Identifier: <LICENSE>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// File        : template_macros.svh
// Author      : <Name> <email>
// Created     : <YYYY-MM-DD>
// Description : <Preprocessor macros shared by this IP. Types, constants and functions belong in a
//               package, not here.>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Revision History
//   Version  Date        Author            Changes
//   1.0.0    YYYY-MM-DD  <Name>            Initial version.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// Notes
//   - Include with `include "template_macros.svh" and add this directory to the include path
//     (+incdir+ / -I). Never include with a relative path.
//   - Macros are global once defined, so every macro carries the TPL_ prefix of this IP.
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// TODO
//   - <Planned work for this file, or "None".>
// ---------------------------------------------------------------------------------------------------------------------------------------------------
// FIXME
//   - <Known bugs or wrong behaviour in this file, or "None".>
// ===================================================================================================================================================

`ifndef TEMPLATE_MACROS_SVH
`define TEMPLATE_MACROS_SVH

// Larger of two values; arguments are parenthesized so expressions expand safely.
`define TPL_MAX(a, b) (((a) > (b)) ? (a) : (b))

// Number of bits needed to index DEPTH entries; at least 1 so DEPTH = 1 still gives a legal width.
`define TPL_IDX_WIDTH(depth) (((depth) > 1) ? $clog2(depth) : 1)

`endif  // TEMPLATE_MACROS_SVH
