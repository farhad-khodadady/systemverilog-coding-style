# ====================================================================================================================================================
# Lint, format and simulation entry points for this repository.
#
#   make check          Verible lint + format check (what CI runs)
#   make format         Reformat every SystemVerilog file in place
#   make sim            Build and run every self-checking testbench with Verilator
#
# Copyright (c) 2026 Farhad Khodadady
# SPDX-License-Identifier: MIT
# ====================================================================================================================================================

SHELL       := bash
.SHELLFLAGS := -eu -o pipefail -c

VERIBLE_LINT   ?= verible-verilog-lint
VERIBLE_FORMAT ?= verible-verilog-format
VERILATOR      ?= verilator
BUILD_DIR      ?= build
SEED           ?= 1

SV_FILES := $(sort $(wildcard templates/*.sv templates/*.svh examples/*/*.sv))

LINT_FLAGS      := --rules_config=.rules.verible_lint --waiver_files=.verible-lint.waiver
FORMAT_FLAGS    := --flagfile=.verible-format.flags
VERILATOR_FLAGS := --binary --timing -j 0 -Wno-fatal

# $(call run_sim,<top>,<files>,<extra flags>): build <top> with Verilator, run it, require "TEST PASSED".
# BUILD_DIR is created first: Verilator creates its --Mdir folder but not missing parent folders.
define run_sim
	mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(3) --top-module $(1) --Mdir $(BUILD_DIR)/$(1) -o $(1) $(2)
	$(BUILD_DIR)/$(1)/$(1) +seed=$(SEED) | tee $(BUILD_DIR)/$(1).log
	grep -q "TEST PASSED" $(BUILD_DIR)/$(1).log
endef

.PHONY: help check lint format format-check sim sim-sync-fifo sim-template clean

help:
	@echo "Targets: check lint format-check format sim sim-sync-fifo sim-template clean"

check: lint format-check

lint:
	$(VERIBLE_LINT) $(LINT_FLAGS) $(SV_FILES)

format-check:
	$(VERIBLE_FORMAT) $(FORMAT_FLAGS) --verify --inplace $(SV_FILES)

format:
	$(VERIBLE_FORMAT) $(FORMAT_FLAGS) --inplace $(SV_FILES)

sim: sim-sync-fifo sim-template

sim-sync-fifo:
	$(call run_sim,sync_fifo_tb,examples/sync_fifo/sync_fifo.sv examples/sync_fifo/sync_fifo_tb.sv,)

sim-template:
	$(call run_sim,template_tb,templates/template_pkg.sv templates/template_fsm.sv templates/template_module.sv templates/template_tb.sv,-Itemplates)

clean:
	rm -rf $(BUILD_DIR)
