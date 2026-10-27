# Verible: install and use

[Verible](https://github.com/chipsalliance/verible) is an open-source SystemVerilog toolchain from
CHIPS Alliance. This repository uses two of its tools:

| Tool                     | What it does                                          | Config file used here                                |
| ------------------------ | ----------------------------------------------------- | ---------------------------------------------------- |
| `verible-verilog-lint`   | Style and correctness checks (naming, `always_ff`, …) | [`.rules.verible_lint`](../.rules.verible_lint), [`.verible-lint.waiver`](../.verible-lint.waiver) |
| `verible-verilog-format` | Re-indents and aligns code; the output *is* the style | [`.verible-format.flags`](../.verible-format.flags)  |

The configuration was checked against Verible **v0.0-4296-g0f262651**. Newer releases add rules but
keep the existing ones compatible.

## 1. Install

Pre-built binaries are on the [releases page](https://github.com/chipsalliance/verible/releases).

**Linux** (static binaries, any distribution):

```bash
VERIBLE_VERSION=v0.0-4296-g0f262651
curl -fsSL "https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/verible-${VERIBLE_VERSION}-linux-static-x86_64.tar.gz" | tar -xz
sudo cp verible-${VERIBLE_VERSION}/bin/* /usr/local/bin/      # or add the bin/ folder to PATH
```

**macOS** (Homebrew):

```bash
brew tap chipsalliance/verible
brew install verible
```

**Windows**: download `verible-<version>-win64.zip` from the releases page, extract it (for example
to `C:\tools\verible`) and add that folder to `PATH`
(*Settings → System → About → Advanced system settings → Environment Variables*).

**Check the installation:**

```bash
verible-verilog-lint --version
verible-verilog-format --version
```

## 2. Daily use

Run from the repository root (the paths to the config files are relative):

```bash
# Lint: prints one line per violation, exits non-zero if there is any
verible-verilog-lint --rules_config_search --waiver_files=.verible-lint.waiver path/to/file.sv

# Format in place
verible-verilog-format --flagfile=.verible-format.flags --inplace path/to/file.sv

# Check formatting without changing files (exit code 1 = "needs formatting")
verible-verilog-format --flagfile=.verible-format.flags --verify --inplace path/to/*.sv
```

With `make` available (Linux, macOS, WSL, MSYS2) the same commands run over the whole repository:

```bash
make check     # lint + format check, exactly what CI runs
make format    # reformat everything
make sim       # run the self-checking testbenches (needs Verilator 5)
```

Useful extras:

```bash
verible-verilog-lint --help_rules=all            # description of every rule
verible-verilog-lint --help_rules=dff-name-style # one rule and its parameters
verible-verilog-lint --print_rules_file          # the active rule set, ready to save as a config
verible-verilog-lint --rules_config_search --autofix=inplace-interactive file.sv  # fix interactively
```

## 3. Use this configuration in your own projects

**Per project (recommended).** Copy the three files to the root of your repository:

```text
.rules.verible_lint      lint rules
.verible-lint.waiver     clock/reset port waiver
.verible-format.flags    formatter options
```

`--rules_config_search` searches upward from each linted file for `.rules.verible_lint`, so files in
any sub-directory pick it up automatically.

**For every project on your machine.** Because the search goes upward, a `.rules.verible_lint` in
your home directory applies to every project below it that has no rules file of its own:

```bash
cp .rules.verible_lint ~/.rules.verible_lint
```

To build your own variant, start from `verible-verilog-lint --print_rules_file > ~/.rules.verible_lint`
and edit it: one rule per line, `-rule` disables it, `rule=param:value;param2:value` configures it.

## 4. Waivers

Prefer fixing the code. When a waiver is justified, keep it next to the code and explain it with a
`LINT:` comment (README section 8):

```systemverilog
// LINT: vendor primitive keeps its upstream port names.
// verilog_lint: waive port-name-suffix
input logic CE,
```

| Scope                         | Syntax                                                                   |
| ----------------------------- | ------------------------------------------------------------------------ |
| Next line                     | `// verilog_lint: waive <rule>`                                          |
| Block of lines                | `// verilog_lint: waive-start <rule>` … `// verilog_lint: waive-stop <rule>` |
| Pattern, whole project        | a `waive --rule=<rule> --regex="..."` line in `.verible-lint.waiver`     |
| Keep the formatter off a block | `// verilog_format: off` … `// verilog_format: on`                      |

## 5. Editor integration (VS Code)

Install the **Verible** extension (`chipsalliance.verible`). It runs `verible-verilog-ls`, which
lints while you type and formats on demand. The workspace settings in
[`.vscode/settings.json`](../.vscode/settings.json) make the editor use the same rules, waivers and
formatter options as the command line:

```json
"verible.arguments": [
    "--rules_config_search",
    "--waiver_files=.verible-lint.waiver",
    "--flagfile=.verible-format.flags"
]
```

Add `"editor.formatOnSave": true` to your user settings to format every file when you save it.

## 6. Pre-commit hook (optional)

Save as `.git/hooks/pre-commit` and make it executable (`chmod +x`). It blocks commits whose staged
SystemVerilog files fail lint or formatting:

```bash
#!/usr/bin/env bash
set -euo pipefail
mapfile -t files < <(git diff --cached --name-only --diff-filter=ACM -- '*.sv' '*.svh')
[ "${#files[@]}" -eq 0 ] && exit 0
verible-verilog-lint --rules_config_search --waiver_files=.verible-lint.waiver "${files[@]}"
verible-verilog-format --flagfile=.verible-format.flags --verify --inplace "${files[@]}"
```

## 7. Continuous integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) installs a pinned Verible release, runs
`make lint` and `make format-check`, and runs the testbenches with Verilator on every push and pull
request. Pinning the version keeps CI results reproducible; update `VERIBLE_VERSION` on purpose.

---

*Verible is developed by CHIPS Alliance and distributed under the Apache License 2.0. It is not part
of, or redistributed by, this repository.*
