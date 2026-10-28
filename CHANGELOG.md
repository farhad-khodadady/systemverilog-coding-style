# Changelog

All notable changes to this style guide are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/): a new major version means existing code may need
changes to stay compliant.

## [1.0.0] - 2026-10-28

### Added

- Style guide with rules in ten sections, each with an ID, a one-line rationale and a lint marker.
- Verible lint configuration (`.rules.verible_lint`) listing every rule explicitly, a waiver file for
  clock and reset port names, and formatter options (`.verible-format.flags`).
- Templates: module, FSM, package, interface, macro header and self-checking testbench.
- Example `sync_fifo` design and self-checking testbench, lint- and format-clean.
- Verible installation and usage guide, VS Code workspace settings, `Makefile` and GitHub Actions CI.
