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

**macOS** (Apple silicon and Intel). The Homebrew tap (`chipsalliance/verible`) lags behind the
releases and its version does not support every option in `.verible-format.flags`, so install the
release binaries instead:

```bash
VERIBLE_VERSION=v0.0-4296-g0f262651
curl -fsSL "https://github.com/chipsalliance/verible/releases/download/${VERIBLE_VERSION}/verible-${VERIBLE_VERSION}-macOS.tar.gz" | tar -xz
mkdir -p ~/.local/bin && cp verible-${VERIBLE_VERSION}-macOS/bin/* ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile     # then open a new terminal
```

If an older Verible was installed with Homebrew, remove it (`brew uninstall verible`) so it does not
shadow the new one.

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
input wire CE,
```

| Scope                         | Syntax                                                                   |
| ----------------------------- | ------------------------------------------------------------------------ |
| Next line                     | `// verilog_lint: waive <rule>`                                          |
| Block of lines                | `// verilog_lint: waive-start <rule>` … `// verilog_lint: waive-stop <rule>` |
| Pattern, whole project        | a `waive --rule=<rule> --regex="..."` line in `.verible-lint.waiver`     |
| Keep the formatter off a block | `// verilog_format: off` … `// verilog_format: on`                      |

## 5. Editor integration (VS Code)

The **Verible** extension (`chipsalliance.verible`) starts `verible-verilog-ls`, Verible's language
server. It underlines lint violations while you type and formats the file on save or on
*Format Document* (`Shift+Alt+F`). This repository ships two files in the `.vscode/` folder that set it up.

### 5.1 The two files

**[`.vscode/extensions.json`](../.vscode/extensions.json)** lists the recommended extension. When
the folder is opened, VS Code offers to install it ("Do you want to install the recommended
extensions?"), and lists it under *Extensions > Workspace Recommendations*.

**[`.vscode/settings.json`](../.vscode/settings.json)** holds the *workspace settings*. VS Code
applies them automatically, on top of your own user settings, whenever this folder is open:

| Setting                                     | What it does                                                                      |
| ------------------------------------------- | --------------------------------------------------------------------------------- |
| `verible.arguments`                         | Command-line options for the language server, so the editor matches the CLI:     |
| ↳ `--rules_config_search`                   | lint with the nearest `.rules.verible_lint`                                       |
| ↳ `--waiver_files=.verible-lint.waiver`     | Waive this file rules                            |
| ↳ `--flagfile=.verible-format.flags`        | format with this style's formatter options                                        |
| `files.associations`                        | Treats `*.svh` as SystemVerilog (the extension only maps `.sv` and `.v`)          |
| `[systemverilog]` → `editor.defaultFormatter` | Uses Verible to format SystemVerilog, even if another Verilog extension is installed |
| `[systemverilog]` → `editor.formatOnSave`   | Formats SystemVerilog files every time they are saved                             |
| `files.eol`, `files.insertFinalNewline`, `files.trimTrailingWhitespace` | LF endings, final newline, no trailing spaces (same as `.editorconfig`) |

Relative paths in `verible.arguments` are resolved from the folder opened in VS Code, so open the
repository root with *File > Open Folder*, not a sub-folder or a single file.

### 5.2 Set it up

**In this repository:** nothing to copy. Install Verible (section 1), open the repository folder
in VS Code and accept the extension recommendation.

**In your own project:** copy the `.vscode/` folder to the project root, next to the three Verible
files from section 3:

```text
my_project/
├── .vscode/
│   ├── extensions.json
│   └── settings.json
├── .rules.verible_lint
├── .verible-lint.waiver
├── .verible-format.flags
└── rtl/ ...
```

If the project already has a `.vscode/settings.json`, merge the entries above into it instead of
replacing the file.

**For every project on your machine:** open *Command Palette* (`Ctrl+Shift+P`) >
*Preferences: Open User Settings (JSON)* and add the same entries there. The paths stay relative,
so each project still needs the three Verible files in its root.

If `verible-verilog-ls` is not on your `PATH`, point the extension to it with
`"verible.path": "C:/tools/verible/verible-verilog-ls.exe"` (or the path on your system).

### 5.3 Check that it works

Open [`templates/template_module.sv`](../templates/template_module.sv): there should be no warnings.
Rename the port `valid_i` to `valid` and the *Problems* panel (`Ctrl+Shift+M`) reports
`port-name-suffix`; undo, and save to see the file formatted. After changing `settings.json`, run
*Developer: Reload Window* so the language server restarts with the new arguments.

## 6. Pre-commit hook (optional)

Save as `.git/hooks/pre-commit` and make it executable (`chmod +x`). It blocks commits whose staged
SystemVerilog files fail lint or formatting:

```bash
#!/usr/bin/env bash
set -euo pipefail
files=()
while IFS= read -r f; do files+=("$f"); done < <(git diff --cached --name-only --diff-filter=ACM -- '*.sv' '*.svh')
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
