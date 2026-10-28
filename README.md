# SystemVerilog Coding Style

[![CI](https://github.com/farhad-khodadady/systemverilog-coding-style/actions/workflows/ci.yml/badge.svg)](https://github.com/farhad-khodadady/systemverilog-coding-style/actions/workflows/ci.yml)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-blue.svg)](LICENSE-DOCS)
[![Code: MIT](https://img.shields.io/badge/code-MIT-green.svg)](LICENSE)

A practical, tool-enforced coding style for synthesizable SystemVerilog RTL and its testbenches.
It comes with a ready-to-use [Verible](https://github.com/chipsalliance/verible) lint and format
configuration, file templates, and an example design that passes lint with zero warnings.

> **About this guide.** These rules come from my own taste and from experience shipping FPGA and
> ASIC RTL. Other engineers may reasonably disagree with some of them. What matters most is that a
> team picks *one* style and lets tools enforce it. Fork it and adapt it.
> — Farhad Khodadady

This is a living document: rules are refined as experience and tools evolve. Released versions are
tagged (`v1.0.0`, `v1.1.0`, …), and every change is listed in [CHANGELOG.md](CHANGELOG.md).

## Contents

- [Quick start](#quick-start)
- [Repository layout](#repository-layout)
- [The style at a glance](#the-style-at-a-glance)
- Rules: [1 Files](#1-files) · [2 Layout](#2-layout--formatting) · [3 Naming](#3-naming) ·
  [4 Types](#4-declarations--types) · [5 Procedural code](#5-procedural-code) ·
  [6 Hierarchy](#6-hierarchy-packages--interfaces) · [7 Preprocessor](#7-compilation--preprocessor) ·
  [8 Comments](#8-comments--documentation) · [9 Verification](#9-verification-code) ·
  [10 Tooling](#10-tooling)
- [References](#references) · [License](#license)

## Quick start

```bash
# 1. Install Verible (see docs/verible.md for Linux, macOS and Windows)
# 2. Lint and format-check everything in this repository
make check
# 3. Lint your own file with this style (run from the repository root)
verible-verilog-lint --rules_config_search --waiver_files=.verible-lint.waiver my_module.sv
verible-verilog-format --flagfile=.verible-format.flags --inplace my_module.sv
```

To adopt the style in another project, copy `.rules.verible_lint`, `.verible-lint.waiver` and
`.verible-format.flags` to its root and start new files from [`templates/`](templates/).
Full instructions: **[docs/verible.md](docs/verible.md)**.

## Repository layout

| Path                                                 | Content                                                          |
| ---------------------------------------------------- | ---------------------------------------------------------------- |
| [`README.md`](README.md)                             | This style guide                                                 |
| [`.rules.verible_lint`](.rules.verible_lint)         | Lint rules: every Verible rule, explicitly enabled or disabled   |
| [`.verible-lint.waiver`](.verible-lint.waiver)       | The single project-wide waiver                                   |
| [`.verible-format.flags`](.verible-format.flags)     | Formatter options (4 spaces, 150 columns, aligned columns)       |
| [`templates/`](templates/)                           | Module, FSM, package, interface, macro header and testbench      |
| [`examples/sync_fifo/`](examples/sync_fifo/)         | A FIFO and its self-checking testbench, written to this style    |
| [`docs/verible.md`](docs/verible.md)                 | Installing and using Verible, editor setup, pre-commit hook, CI  |
| [`.vscode/`](.vscode/)                               | VS Code workspace settings: Verible lint and format on save      |
| [`Makefile`](Makefile), [`.github/`](.github/)       | `make check`, `make sim` and the CI workflow that runs them      |
| [`CHANGELOG.md`](CHANGELOG.md)                       | Version history of the style                                     |

## The style at a glance

```systemverilog
`default_nettype none

module pulse_counter #(
    parameter int unsigned WIDTH = 8  // Counter width in bits
) (
    input  wire              clk,      // Clock
    input  wire              rst_n,    // Asynchronous reset, active low
    input  wire              pulse_i,  // Count this pulse
    output logic [WIDTH-1:0] count_o   // Number of pulses seen
);

    timeunit 1ns; timeprecision 1ps;

    logic [WIDTH-1:0] count_q;  // Register output
    logic [WIDTH-1:0] count_d;  // Register next-state value

    always_comb begin
        count_d = count_q;
        if (pulse_i) begin
            count_d = count_q + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_q <= '0;
        end else begin
            count_q <= count_d;
        end
    end

    assign count_o = count_q;

endmodule : pulse_counter

`default_nettype wire
```

---

## Rules

Each rule has an ID for code-review comments ("see 5.4") and a one-line reason. **Lint** means the
rule is checked by Verible with the configuration in this repository; the rest are checked in review.

### 1. Files

| ID  | Rule                                                                                                | Why                                                                        | Lint |
| --- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | :--: |
| 1.1 | One module, interface or package per file; the file name equals the unit name.                       | Any unit is found from its name, and file lists stay obvious.             |  ✓   |
| 1.2 | File and unit names are `lower_snake_case`; `.sv` for compiled files, `.svh` for include files.     | Portable across case-insensitive file systems and every tool.             |  ✓   |
| 1.3 | Role suffixes: `_pkg.sv`, `_if.sv`, `_tb.sv`; macro headers `*_macros.svh`.                          | The role of a file is visible in a directory listing.                     |      |
| 1.4 | Keep modules small and single-purpose.                | Small units are easier to review, reuse and verify in isolation.          |      |
| 1.5 | UTF-8, LF line endings, a final newline (enforced by `.editorconfig` and `.gitattributes`).         | Identical bytes on Windows, Linux, and Mac, so no whole-file diffs.              |  ✓   |

### 2. Layout & formatting

| ID  | Rule                                                                                                 | Why                                                                     | Lint |
| --- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | :--: |
| 2.1 | Indent with 4 spaces; never tabs.                                                                    | Renders the same in every editor, diff and code-review tool.           |  ✓   |
| 2.2 | Lines are at most 150 columns. This is my preference; 100 or 120 is fine if the team agrees on it.  | Room for aligned declarations with trailing comments.                  |  ✓   |
| 2.3 | `verible-verilog-format` output *is* the layout. Run it before every commit.                         | No layout discussions in code review; the tool decides.                |  ✓   |
| 2.4 | Every `if`, `else`, `for`, `always*` and `initial` body gets `begin`/`end`, even for one statement. | A line added later cannot silently fall outside the branch.            |  ✓   |
| 2.5 | One declaration and one statement per line.                                                          | Clean diffs and meaningful `git blame`.                                |      |
| 2.6 | Group code into the sections of the [templates](templates/), enclosed in full-width `// ====` banners (150 columns); `// ----` lines divide the parts inside a block such as the file header. | Every file has the same shape, so anything is quick to find.           |      |
| 2.7 | No blank lines inside port, parameter and connection lists. To show groups, an optional `//` comment line may head each one. | The formatter aligns a list only up to a blank line; comment lines keep the whole list in one aligned block. |  ✓   |

### 3. Naming

#### 3.1 General

| ID  | Rule                                                                                                         | Why                                                                         | Lint |
| --- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- | :--: |
| 3.1 | `lower_snake_case` for modules, signals, variables, instances, functions, tasks and types.                   | One convention for everything that is not a constant.                      |  ✓   |
| 3.2 | `UPPER_SNAKE_CASE` for `parameter`, `localparam`, enum labels and macros.                                    | Constants stand out from signals at a glance.                              |  ✓   |
| 3.3 | Names describe purpose (`rd_ptr_q`, not `p2`). Only common abbreviations: `addr cnt en req ack rd wr idx`.   | Code is read far more often than it is written.                            |      |
| 3.4 | Ports end in their direction: `_i`, `_o`, `_io`. Active-low ports add `n`: `_ni`, `_no`.                     | The direction is visible at every use, including in the parent module.     |  ✓   |
| 3.5 | Register outputs end in `_q`, their next-state value in `_d` (`count_q <= count_d`). A value delayed by N clock cycles ends in `_qN` (`_q1`, `_q2`, …); for longer or parameterized delays, a packed array `logic [DELAY:1][W-1:0] data_q`, where `data_q[N]` is the value delayed by N cycles. | You can see which signals are flip-flops and which value feeds them; the number is always the delay in clock cycles. |  ✓   |
| 3.6 | Other internal combinational signals get no suffix.                                                          | Short names for the common case; the suffixes above carry the meaning.    |      |
| 3.7 | Active-low internal signals end in `_n` (`cs_n`); active-high signals have no polarity suffix.               | Polarity is explicit wherever it is not the default.                       |      |
| 3.8 | Types end in `_t`, enum types in `_e`, packages in `_pkg`, interfaces in `_if`.                              | The kind of an identifier is visible without looking it up.   |  ✓   |
| 3.9 | Instances are prefixed `u_` (`u_sync_fifo`, `u_fifo_rx`); generate blocks are prefixed `g_`.               | Instances and generate scopes are easy to find in hierarchy and netlists.  | `g_` ✓ |

#### 3.2 Clocks and resets

| Signal            | Meaning                                    |
| ----------------- | ------------------------------------------ |
| `clk`             | The clock of a single-clock module         |
| `clk_<domain>`    | One of several clocks: `clk_sys`, `clk_axi` |
| `rst_n`           | Asynchronous reset, active low (default)   |
| `rst`             | Asynchronous reset, active high            |
| `srst_n` / `srst` | Synchronous reset, active low / high       |
| `rst_<domain>_n`  | Asynchronous reset of one clock domain     |

| ID   | Rule                                                                                                           | Why                                                                              | Lint |
| ---- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | :--: |
| 3.10 | Name clocks and resets as in the table; they take no `_i` suffix (waived in `.verible-lint.waiver`).            | The name alone gives domain, polarity and sync/async; a clock is always an input. |  ✓   |
| 3.11 | In multi-clock modules, prefix signals with their domain (`sys_count_q`, `axi_ready`).                          | A signal used in the wrong domain is visible in review.                         |      |
| 3.12 | Default reset style: asserted asynchronously, released synchronously by a per-domain reset synchronizer.        | Resets even without a running clock, and release meets recovery/removal timing. |      |
| 3.13 | Use one reset style per module. FPGA-only designs may use `srst` (synchronous, active high) instead.            | Vendor flip-flops and DSP/RAM blocks map synchronous resets more efficiently.   |      |
| 3.14 | Reset only what needs it: FSM state, valid bits, counters. Datapath registers qualified by a valid get none.    | Less reset fan-out and area, better timing and RAM/SRL inference.              |      |
| 3.15 | Every clock-domain crossing goes through a dedicated synchronizer module and is marked with `// CDC:`.           | RTL simulation does not find CDC bugs, so they must be easy to audit.           |      |

### 4. Declarations & types

| ID   | Rule                                                                                                                 | Why                                                                                   | Lint |
| ---- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | :--: |
| 4.1  | Use 4-state `logic` for all RTL signals.                                                                   | X from a missing reset or a multiple driver stays visible instead of becoming 0. |      |
| 4.2  | Declare `input` and `inout` ports as nets, `input wire`, `inout wire`; declare `output` ports as variables, `output logic`. A `wire` without a type is `logic`; add the type only for a typedef: `input wire word_t data_i`. | A net input cannot be silently overwritten inside the module, and `default_nettype none` (7.1) requires the explicit `wire`. A variable output may be assigned directly in `always_ff`/`always_comb`, and a second driver is a compile error instead of an X in simulation. |      |
| 4.3  | Use 2-state types (`bit`, `int`, `int unsigned`, `byte`) for verification code, loop indices and parameters.          | Faster simulation where X/Z have no meaning.                                         |      |
| 4.4  | Give every parameter an explicit type: `parameter int unsigned DEPTH = 16`.                                           | No implicit width or sign surprises.                                                 |  ✓   |
| 4.5  | Declare `signed` explicitly for two's-complement arithmetic; never mix signed and unsigned operands without a cast.   | One unsigned operand makes the whole expression unsigned.                            |      |
| 4.6  | `typedef` every user-defined type; types used by more than one module live in a package.                               | One definition, and connections are type-checked.                                    |  ✓   |
| 4.7  | Enums have an explicit base type, `typedef enum logic [1:0] {...} state_e;`, and explicit values when encoding matters. | Fixed width and known encoding; without a base type an enum is a 2-state `int`. |  ✓   |
| 4.8  | Group fields that travel together in a `struct packed` and pass it through one port.                                  | Adding a field changes one typedef instead of every port list.                       |      |
| 4.9  | In RTL, use only `union packed` with members of equal width, to view the same bits in different ways.                  | Packed unions are synthesizable; tagged and unpacked unions generally are not.       |      |
| 4.10 | Packed dimensions descend (`[W-1:0]`); unpacked dimensions use the size form (`[DEPTH]`) or ascend.                    | One ordering everywhere avoids reversed-slice bugs.                                 |  ✓   |
| 4.11 | Use packed arrays for values handled as numbers or bit fields; unpacked arrays for memories and independent elements.  | Matches how synthesis infers RAMs and how simulators store data.                     |      |
| 4.12 | Use fill literals `'0`, `'1`; binary literals are fully sized.                                                         | Fill literals stay correct when a width parameter changes.                           |  ✓   |
| 4.13 | Constants: `localparam` inside modules, `localparam` in packages (a package `parameter` cannot be overridden anyway).   | The keyword says what the constant really is.                                       |  ✓   |
| 4.14 | Declare at module scope: registers, nets between blocks, flags read in several places. Declare inside the block: loop indices and temporaries used only there. | Smallest useful scope, while state and shared nets stay visible. |      |
| 4.15 | Block-local variables in `always_comb` are written before they are read; declare none in `always_ff`.                 | A local read before it is written keeps its old value, which describes storage. |      |

### 5. Procedural code

| ID   | Rule                                                                                                                         | Why                                                                                    | Lint |
| ---- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | :--: |
| 5.1  | `always_ff` for flip-flops, `always_comb` for combinational logic, `always_latch` only for an intended latch. No plain `always` in RTL. | Tools check the intent, for example a latch inferred in `always_comb`. |  ✓   |
| 5.2  | Nonblocking `<=` only in `always_ff`; blocking `=` only in `always_comb`.                                                    | Avoids simulation races and simulation/synthesis mismatches.                           |  ✓   |
| 5.3  | Separate always blocks for unrelated logic; place an `always_comb` next to the `always_ff` it feeds.                          | Each block describes one piece of hardware, and related blocks are read together.     |      |
| 5.4  | Write next-state logic either in `always_comb` into `_d` (the `always_ff` then only does reset and `x_q <= x_d`) or directly in the `always_ff`; choose whichever reads more clearly. Use the `_d` form when other logic needs the next value. | Simple counters and pipelines read best in one block; the `_d` form exposes the next value for look-ahead flags, outputs and assertions. |      |
| 5.5  | Start every `always_comb` with a default assignment to every signal it drives.                                                | No latches, and no missing-branch bugs.                                                |      |
| 5.6  | Async reset: `always_ff @(posedge clk or negedge rst_n)` with the reset branch first (`if (!rst_n)`).                         | The form every synthesis tool recognizes.                                              |      |
| 5.7  | Every `case` has a `default`. Do not use the `full_case`/`parallel_case` synthesis pragmas.                                    | Pragmas change synthesis only, so they create simulation/synthesis mismatches. |  ✓   |
| 5.8  | Plain `case` by default. `unique case` when items are mutually exclusive; `priority case` when the first match must win. `unique0` only where no match is legal and nothing must happen. | The simulator checks the claim the keyword makes, and synthesis can use it. |      |
| 5.9  | The `default` branch assigns a defined value. Assign `'x` only to a datapath don't-care whose output is qualified by a valid, with a comment; never to control signals or state. | X in control logic hides bugs (X-optimism) and can make RTL and gate-level simulation disagree. |      |
| 5.10 | FSMs: enum state type, `state_q`, `unique case (state_q)`, and a `default` that recovers to a safe state. Write it as `always_ff` + `always_comb` with `state_d`, or in a single `always_ff`, whichever is clearer. In the single-block form every output assigned in it is registered. | Readable, state names in waveforms, recovery from illegal states; a single block cannot produce an output in the same cycle as the state. |      |
| 5.11 | Use `++`, `--` and `+=` only for loop variables and in verification code; never on a signal in `always_ff`.                    | These operators are blocking assignments, so in `always_ff` they cause races. |  ✓   |
| 5.12 | `for (int i = 0; i < N; i++)` with the index declared in the loop and constant bounds in RTL.                                | The loop is unrolled at elaboration and the index cannot leak.                        |      |
| 5.13 | Functions and tasks are `automatic`, have typed arguments and a named end (`endfunction : name`).                            | Each call gets its own variables: no state kept between calls, safe for recursion and concurrent calls. |  ✓   |
| 5.14 | In RTL, use functions only. Tasks are for verification code that consumes time; use a `void` function when nothing waits.  | Functions are zero-time by definition and always synthesizable.          |      |
| 5.15 | No delays (`#`), `initial`, `force` or `wait` in synthesizable code. FPGA RAM initialization with `$readmemh` is the exception and is marked `// NOTE: FPGA-only`. | Synthesis ignores them, so the simulation would describe different hardware. |      |
| 5.16 | Label an `always_*` block that declares local variables, with a `p_` prefix: `always_comb begin : p_next_level` … `end : p_next_level`. Other blocks need no label. | Locals of an unnamed block get a tool-generated scope (or none) in simulators and waveform viewers; the label makes them easy to find. |      |

### 6. Hierarchy, packages & interfaces

```systemverilog
module sync_fifo_wrapper
    import fifo_pkg::*;       // in the header: visible to parameters and ports, local to this module
#(
    parameter int unsigned DEPTH = 16
) (
    ...
```

| ID   | Rule                                                                                                            | Why                                                                                       | Lint |
| ---- | --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | :--: |
| 6.1  | Import packages in the module header, right after the module name and before the parameter list. Never at file scope. | Package items are usable in parameters and ports, but stay local to the module. A file-scope import leaks into every file compiled after it and depends on compile order. |      |
| 6.2  | Use a wildcard import (`pkg::*`) in every file that uses the package; write `pkg::NAME` when two packages could define the same name. | Wildcard items are only imported when used, so there is no cost; the explicit form removes ambiguity. |      |
| 6.3  | Shared types, constants and functions go in named packages; nothing is declared in `$unit` (outside any module or package). | Declarations in `$unit` depend on compile order and are visible everywhere.             |      |
| 6.4  | Connect ports by name: `.data_i (wr_data)`. No positional connections and no `.*`.                               | Every connection is explicit and searchable; `.*` silently connects any signal with a matching name. |  ✓   |
| 6.5  | Override parameters by name: `#(.DEPTH(16))`. Never use `defparam`.                                              | Overrides are visible at the instance.                                                    |  ✓   |
| 6.6  | Label every generate block (`g_<name>`); no `generate`/`endgenerate` keywords; `genvar` declared in the loop.   | Stable hierarchical names for debug, constraints and waivers.                             |  ✓   |
| 6.7  | Interfaces have one modport per role (`source`, `sink`, `monitor`), and modules use `<name>_if.<modport>` ports.   | Directions are checked by the tools, and a protocol change is made in one place. |      |
| 6.8  | Keep plain ports, not interfaces, on the chip top level and on vendor IP-packager boundaries.                      | Many FPGA/ASIC flows and IP packagers do not support interface ports.                    |      |
| 6.9  | Close every named construct with its label: `endmodule : name`, `endpackage : name`, `end : label`, …             | You can see what ends where, and the tool checks that the labels match.       |  ✓   |
| 6.10 | Instantiate a sub-module in the section of the logic it belongs to, next to the code that drives or uses its ports. No separate "instances" section. | One function of the module is read in one place, including the blocks it is built from. |      |

### 7. Compilation & preprocessor

| ID  | Rule                                                                                                                     | Why                                                                                | Lint |
| --- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- | :--: |
| 7.1 | `` `default_nettype none `` before the first module of a file, `` `default_nettype wire `` at the end of it.             | A typo becomes a compile error instead of an implicit 1-bit wire; restoring the default keeps legacy files that rely on implicit nets compiling. |      |
| 7.2 | `timeunit` and `timeprecision` as the first items of every module, interface and testbench; never `` `timescale ``.      | Time units belong to the unit, not to whichever file happened to be compiled before it. |      |
| 7.3 | Include files (`.svh`) contain macros only; types, constants and functions belong in packages.                           | `` `include `` is a textual copy; packages are compiled once and scoped.          |      |
| 7.4 | Put `` `include `` directives at the top of the file, after the header; use the bare file name and set the path with `+incdir+`/`-I`. | Macros are global from the point of definition; relative paths break when files move. |      |
| 7.5 | Every `.svh` and every package file has an include guard: `` `ifndef NAME_SV `` / `` `define NAME_SV `` / `` `endif // NAME_SV ``. | Including or listing a file twice is harmless.                                    |      |
| 7.6 | Macros are `UPPER_SNAKE_CASE` with an IP prefix (`FIFO_`) and parenthesized arguments; prefer constants and functions to macros. | Macros are global and untyped; the prefix prevents collisions.                   |  ✓   |
| 7.7 | Simulation-only code (assertions, parameter checks) is guarded with `` `ifndef SYNTHESIS ``.                              | Synthesis tools see only the hardware.                                             |      |

### 8. Comments & documentation

| ID  | Rule                                                                                                                  | Why                                                                     |
| --- | --------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 8.1 | Every file starts with the standard header: copyright, SPDX license, file, author, creation date, description, revision history, notes, TODO and FIXME. Keep the TODO and FIXME sections even when empty ("None."). | Ownership, license and intent are clear even outside version control. |
| 8.2 | Write self-describing code; comments explain *why*, not *what*.                                                         | The code already says what; the reason is what gets lost.             |
| 8.3 | Use the tags below, in the form `// TAG: text` or `// TAG(owner): text`. List every TODO/FIXME of a file in its header, and also tag it inline next to the code it concerns. | `git grep -n "FIXME"` before a release finds every open item.         |

| Tag     | Use it for                                                                                   |
| ------- | -------------------------------------------------------------------------------------------- |
| `TODO`  | Planned work or a missing feature. Not a bug.                                                |
| `FIXME` | Known wrong behaviour that must be fixed before release.                                     |
| `HACK`  | A deliberate workaround: say why it is needed and what the proper fix is.                    |
| `NOTE`  | A non-obvious decision, assumption or constraint the reader must know.                       |
| `CDC`   | A clock-domain crossing: name the source and destination domains and the synchronizer used.  |
| `LINT`  | The justification for a lint waiver, on the line above the waiver.                           |

### 9. Verification code

| ID  | Rule                                                                                                           | Why                                                                     | Lint |
| --- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | :--: |
| 9.1 | The testbench top is `<dut>_tb` in `<dut>_tb.sv`, and the DUT instance is `u_dut`.                              | Every testbench can be found and scripted the same way.                |      |
| 9.2 | Testbenches check themselves against a reference model written independently of the DUT, and finish with exactly one `TEST PASSED` or `TEST FAILED` line. | No waveform inspection to decide pass or fail; CI can check the result. |      |
| 9.3 | Every testbench has a watchdog that calls `$fatal` after a timeout.                                             | A hung test fails instead of hanging the regression.                   |      |
| 9.4 | Drive DUT inputs on the inactive clock edge (or through a clocking block) and sample on the active edge.         | No races between testbench and DUT.                                    |      |
| 9.5 | Random tests take `+seed=<n>` and log it; waveform dumping is opt-in (`+dump=1`).                               | Any failure can be reproduced, and regressions do not fill the disk.   |      |
| 9.6 | Cover the corner cases you claim to test (full, empty, wrap-around) and fail the test if one was never reached.  | A passing test that never reached the interesting cases proves nothing. |      |
| 9.7 | Embed assertions (SVA) for protocol rules and invariants in RTL and interfaces; label them `assert_<what>`.      | Bugs are caught where they happen, not where they become visible.       |      |
| 9.8 | Queues end in `_queue` (`expected_queue`), never `_q`, which is reserved for register outputs.                 | A reader never mistakes a testbench data structure for a flip-flop.      |      |

### 10. Tooling

| ID   | Rule                                                                                                          | Why                                                                     |
| ---- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 10.1 | Every file passes `verible-verilog-lint` with this configuration and is formatted with `verible-verilog-format`. | The style is enforced by tools, not by memory.                          |
| 10.2 | Waive a lint rule only on the line that needs it, with a `// LINT:` reason ([docs/verible.md, section 4](docs/verible.md#4-waivers)). | Every exception is deliberate and explained.                            |
| 10.3 | CI runs lint, the format check and the testbenches on every push and pull request.                            | Nothing that breaks the style or the tests reaches `main`.              |

---

## References

The rules above are written in my own words. The works below are cited for further reading; no text
or code is reproduced from them.

- IEEE Std 1800-2023, *IEEE Standard for SystemVerilog: Unified Hardware Design, Specification, and
  Verification Language*.
- S. Sutherland, S. Davidmann, P. Flake, *SystemVerilog for Design*, 2nd ed., Springer, 2006
  (ISBN 978-0-387-33399-1).
- C. E. Cummings, "Nonblocking Assignments in Verilog Synthesis, Coding Styles That Kill!",
  SNUG 2000.
- C. E. Cummings, "full_case parallel_case, the Evil Twins of Verilog Synthesis", SNUG 1999.
- C. E. Cummings, D. Mills, S. Golson, "Asynchronous & Synchronous Reset Design Techniques — Part
  Deux", SNUG 2003.
- AMD, *UltraFast Design Methodology Guide for FPGAs and SoCs* (UG949)
- lowRISC, [Verilog Coding Style Guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md):
  a widely used open style guide. Several naming conventions here (`_i`/`_o`, `_d`/`_q`) are
  deliberately the same, so code can move between projects.
- CHIPS Alliance, [Verible documentation](https://chipsalliance.github.io/verible/) and
  [lint rule reference](https://chipsalliance.github.io/verible/lint.html).

## License

You are free to use, adapt and share everything here, including in commercial work, as long as you
credit the source.

- **Documentation** (this README and [`docs/`](docs/)) is licensed under
  [Creative Commons Attribution 4.0 International](LICENSE-DOCS) (CC BY 4.0). Credit
  "Farhad Khodadady, SystemVerilog Coding Style" with a link to this repository, and state if you
  changed it.
- **Code** (templates, examples, tool configuration, `Makefile`, CI) is licensed under the
  [MIT License](LICENSE). Keep the copyright and license notice with copies of the code, for example
  in a `LICENSE` or `NOTICE` file of your project.

Verible, Verilator and the other tools mentioned are separate projects under their own licenses and
are not distributed with this repository. All trademarks belong to their respective owners.

## Contributing

Suggestions, disagreements and contributions are welcome.

- **Discuss a rule:** open an [issue](https://github.com/farhad-khodadady/systemverilog-coding-style/issues)
  describing the rule and the reason behind your alternative.
- **Propose a change:** fork the repository, create a branch from `dev`, make your change, run
  `make check`, and open a pull request against `dev`. Every pull request is reviewed before it is merged.

---

<p align="center">
  <b>SystemVerilog Coding Style</b> · written and maintained by <b>Farhad Khodadady</b>, Senior ASIC/FPGA Design Engineer
</p>
