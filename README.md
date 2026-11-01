# Dotfiles

This repository contains the WSL shell and Neovim setup, Lazygit configuration,
global Codex instructions, and snapshots of the Windows terminal settings. Local
editor binaries live in `~/.local/bin`; put that directory before system binaries
in `PATH`.

## Restore on another machine

The supported starting point is Linux or WSL, with Bash and Git. Windows terminal
settings are restored separately. This repository is configuration, not a machine
backup: credentials, SSH keys, Git authentication, project files, installed plugins,
language servers, fonts, and local binaries are not included.

1. Clone this repository into a permanent directory such as `~/projects/dotfiles`.
   Managed configuration links point into the checkout, so keep it there.
2. From the checkout run `bash bin/install.sh`. Start with Bash and Git; the
   installer uses sudo for distribution prerequisites. On Arch it performs the
   synchronized upgrade required by pacman; Debian and Amazon Linux install
   prerequisites without a full system upgrade.
3. Open a new zsh terminal. The installer preserves existing Oh My Zsh/custom
   contents, installs missing shell components, and creates the alias trash
   directory. It does not change your login shell; choose zsh separately if desired.
4. On Windows, install CaskaydiaCove NF and restore the terminal snapshots below.
   Check the WSL distribution name (`Ubuntu` in the snapshots).
5. Restore credentials separately and authenticate GitHub/Copilot as needed.
   `~/.keys` is optional and must never be added to this repository.

The installer installs checksum-verified editor binaries, Node/npm, Lazygit,
configuration links, and global Codex documents. It restores plugins from the
checkout's `lazy-lock.json`, runs their build hooks, installs the configured
Treesitter parsers, and waits for Pyright. Network/build failures stop the run.
It uses a disposable configuration copy while restoring plugins so the source
lockfile is preserved, including any local edits. Existing shell repositories
are reused without resetting or updating their contents. Existing managed files
are backed up before replacement; matching links and files are reused.

Review the Git identity in `.zshrc`: interactive launches write that name and
email into global Git configuration. The installer does not install optional
language-specific tools (Black, Pylint, rust-analyzer, or Stylua), fonts, credentials,
or Windows terminal settings. Existing NVM initialization can select a different
Node version in interactive shells; `~/.local/bin` remains the managed tool path.

## Minimal troubleshooting and rollback

| Symptom | First check or recovery |
| --- | --- |
| Wrong Neovim version or startup errors | `type -a nvim` and `~/.local/bin/nvim --version`; the configuration needs 0.11.7 or newer. Put `~/.local/bin` first in `PATH`. |
| Need a working editor immediately | `nvim --clean` bypasses this configuration and plugins; `nvim --standard` keeps the configuration with a simpler layout. |
| Broken shell startup | Use `bash --noprofile --norc` or `zsh -f`; inspect the Oh My Zsh/plugin/theme paths before loading `.zshrc`. |
| Broken configuration links | Confirm the checkout still exists, then rerun `setup_symlinks` as shown below. |
| Broken plugin after an update | Run `:Lazy restore` using the reviewed `lazy-lock.json`; avoid `:Lazy update` during recovery. |
| Missing syntax, completion, or formatting | Run `:checkhealth`, `:Mason`, and `:LspInfo`; check Node/npm, compilers, tree-sitter, and the relevant formatter on `PATH`. |
| Missing math or preview | Check `~/.local/bin/utftex`, `~/.local/bin/termtex`, and Node.js; see the Markdown preview notes below. |
| Wrong colors or missing glyphs | Check the terminal font and imported palettes. Automatic editor appearance detection uses Windows PowerShell; on plain Linux select a colorscheme manually. |

To undo a managed link replacement, remove only that symlink and move the matching
adjacent `*.backup.XXXXXXXX/original` back to its previous pathname. Inspect the
backup first; multiple backups can exist. The symlink installer preserves existing
files and broken links, but it does not back up every external component installed
by the full installer.

Before moving machines, commit and push the intended checkout changes and verify
them from the remote. An untracked README, Lua module, terminal palette, or wrapper
will not appear in a fresh clone. Preserve `lazy-lock.json` with the configuration;
it pins plugins, not every external dependency or build artifact.

## Global Codex instructions

`configs/codex/AGENTS.md` contains the portable preferences and shared workflow
rules. Project paths and any future CPU/hardware-specific notes belong in
`configs/codex/machine-context.md`, which the global instructions reference.
Review that file's original WSL/Windows paths when restoring on another machine.
Project workflow rules remain in each project's own `AGENTS.md`.

The installer copies these files and the two referenced runbooks into
`${CODEX_HOME:-$HOME/.codex}`. This follows Codex's documented
[global instructions location](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
It uses regular files so a Windows Codex home on `/mnt/c` can read them without
following WSL symlinks. Existing differing files or links receive adjacent
`*.backup.XXXXXXXX/original` backups; identical regular files are left alone.
Other Codex configuration, credentials, and skills are left in place.

To install only the Codex documents, without package or editor downloads:

```bash
bash <<'SH'
set -e
source lib/config.sh
setup_codex_config
SH
```

`setup_symlinks` and the full installer also call `setup_codex_config`. If Windows
and WSL use separate Codex homes, run this once for each home by setting
`CODEX_HOME` for that invocation; unset it to target the Linux `~/.codex` default.
Edit the tracked files in `configs/codex/` and rerun this step to deploy changes.
Start a new Codex session to pick up the installed instructions. An existing
`AGENTS.override.md` takes precedence over `AGENTS.md` and is left untouched.

## Editor installation

To update the editor and its configuration without installing system packages or
shell components, run from the repository (distribution prerequisites must exist):

```bash
bash <<'SH'
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
source lib/config.sh
source lib/tools.sh
install_node
install_lazygit
install_neovim
install_delta
install_tree_sitter
install_utftex
install_termtex
setup_symlinks
restore_neovim_plugins
SH
```

These steps preserve replaced files, directories, and links in adjacent
`*.backup.XXXXXXXX/original` paths. Running them again leaves matching links alone.
Plugin restoration uses the pins in `configs/nvim/lazy-lock.json`.

| Component | Version policy | Installation |
| --- | --- | --- |
| Neovim | Stable 0.11.7 minimum; installs 0.11.7 when needed | `~/.local/opt/neovim-v0.11.7`, linked into `~/.local/bin` |
| Delta | Pinned 0.20.1 | `~/.local/bin/delta` |
| Tree-sitter CLI | Pinned 0.25.10; needed to build the LaTeX parser | `~/.local/bin/tree-sitter` |
| utftex | Pinned libtexprintf 1.31; built with GCC and Make | `~/.local/bin/utftex` |
| termtex | Pinned c407d5cf5251; built with a temporary, verified Go 1.27.3 toolchain | `~/.local/bin/termtex` |
| Lazygit | Pinned 0.56.0 | `~/.local/bin/lazygit` |
| Node.js / npm | Minimum 22.22.0; installs 22.22.0 when needed | `~/.local/opt/node-v22.22.0`, linked into `~/.local/bin` |

Tool downloads use official upstream release archives and pinned SHA256 checksums.
Linux x86_64 and ARM64 are supported. The ARM64 Delta archive requires
glibc. The Markdown preview plugin's prebuilt Linux server supports x86_64 only;
the full plugin restore reports an error if that binary is unavailable.
Updating a binary pin requires updating its matching checksums in `lib/tools.sh`.

The editor needs Lazygit, Git, Node.js, ripgrep, and the configured Nerd Font.
Markdown preview uses the plugin's prebuilt application; avoid rebuilding its old
Node dependencies. Browser navigation patches and their checks are documented in
`configs/nvim/markdown-preview/README.md`.

Markdown math renders inside the editor using `utftex` for both `$...$` and
`$$...$$`. Formulas unsupported by `utftex` fall back to `termtex`, including
labeled arrows such as `\xrightarrow{label}`. The LaTeX Treesitter parser installs
alongside the Markdown parsers.
Standalone display equations replace their raw LaTeX while reading. Moving the
cursor into a block or selecting across it reveals the source; leaving restores
the rendered equation. `markdown_math.lua` adapts the plugin's existing math
renderer through its custom-handler interface.
`Space mr` toggles Markdown rendering; the source remains unchanged. Complex TeX
may exceed the converter's supported syntax; use `Space mv` for browser preview.

`setup_symlinks` links both Lazygit theme files and the `lazygit-diff` Delta wrapper,
in addition to the shell, tmux, and Neovim configurations. The editor chooses its
light or dark Lazygit theme when opening the terminal.

## Neovim configuration ownership

`configs/nvim/init.lua` keeps basic options, remaining plugin declarations, and
calls the feature modules under `configs/nvim/lua/`:

| Module | Responsibility |
| --- | --- |
| `theme.lua` | Windows theme detection, persistent highlights, and asynchronous focus refresh |
| `workspace.lua` | File/Git sidebar setup, pane navigation, and terminal titles |
| `framed_layout.lua` | Rounded pane geometry, native split transitions, and editor-local buffer bar |
| `buffers.lua` | Buffer bar and closing the current buffer without removing panes |
| `git_review.lua` | Commit comparisons, synchronized diff scrolling, and the Lazygit terminal |
| `git_graph.lua` | Asynchronous compact branch history and commit-to-working-tree selection |
| `git_panel_refresh.lua` | Visible Git sidebar polling |
| `reading.lua` | Sticky context, indentation scope, and interactive scrollbars |
| `code_outline.lua` | Aerial outline in the lower-left frame, following the editor buffer |
| `language_tools.lua` | Completion, diagnostics, language servers, and one format-on-save hook |
| `markdown_source.lua` | Browser-to-source navigation bridge |

Neovim's custom highlights have one owner. Framed workspaces use filled quarter-circle
corners and half-block edges, with the pane color as foreground and the surrounding
color as background. Panes, gutters, and editor-local tabs share a lighter shade of
the colorscheme background; the focused pane is lighter again. The installed
CaskaydiaCove Nerd Font includes these corner glyphs. `:PaneStyle outline` restores
the homogeneous background and thin rounded frames; `:PaneStyle filled` restores
filled edges. For a persistent override, set `vim.g.framed_border_style = "outline"`
before theme setup.

The pinned VS Code Modern theme follows Windows appearance automatically: Light
Modern and Dark Modern use neutral white/grey surfaces and blue accents. The
semantic palette in `theme.lua` owns pane, gutter, buffer tab, status bar, selection,
and diff highlights. Lazygit's two YAML palettes and Delta's pager colors match
these light/dark values; theme integration checks guard the shared Lazygit colors.
The status bar retains its existing sections, with a blue mode badge and neutral
backgrounds. Other installed colorschemes remain available for manual previews.
Command entry, Git Graph previews, and messages use 5 percent transparency,
independent of the opaque workspace panes. `theme.popup_blend` owns this setting;
the painted command cursor remains opaque.
`popup_backdrop.lua` temporarily mirrors the rendered panes into the existing
native background window, so terminal transparency reveals the document beneath
floating panes. The snapshot is removed when the popups close.

The Bufferline winbar adapters, Noice painted cursor, and sidebar adapters depend
on the pinned plugin versions. Run the integration checks when changing those pins.

In framed workspaces, Files, Editor, and Git each have an interior header row.
The buffer bar occupies the editor's second interior row; Files and Git use that
row for their own content headings. The rounded outer edges remain uninterrupted.
Native split layouts and standard mode retain the global buffer bar.

Git status occupies the upper-right frame; a compact commit graph sits below it.
`Space gh` toggles the graph. `Ctrl-w j` and `Ctrl-w k` move between the two right
panes. In the graph, Enter shows the selected commit against its first parent in
Diffview; the initial commit compares against an empty tree. Graph `w` compares
the selected commit with current working files, including uncommitted changes.
`q` in Diffview returns to the workspace.
In Git Graph, `p` previews the full selected commit subject, branch/tag names, and
commit hash in a wrapped popup aligned to the editor's right edge, outside the
sidebar. Moving the cursor or pressing Escape closes it.
Graph `r` refreshes history and graph `q` hides it. History refreshes on focus gain
or when entering its buffer, loading at most 300 commits across branches.
The graph uses native Git output and does not check out branches. It collapses
when the terminal is too short and returns when space permits.

The current file's outline appears below Files, showing code symbols or Markdown
headings. `Space fo` toggles it; `Ctrl-w j` / `Ctrl-w k` move between Files and
Outline. Enter or double-click jumps to a symbol in the editor; `p` previews its
location without leaving the outline; `q` hides the outline. Its horizontal divider
is draggable, and its width follows the Files column. Both lower panels collapse
on short terminals and return when space permits. Standard mode opens neither.

`Space w` followed by an arrow navigates panes. Left/Right move across columns and
restore the last used pane in each sidebar; Up/Down switch between Files/Outline
or Git/Graph. Arrow navigation wraps at the edges: Git to Files, Git Graph to
Outline, and top to bottom within each sidebar. Missing lower panes fall back to
their upper pane. `Ctrl-w h/j/k/l` retains navigation without wrapping.
Space-Up/Down continue to jump between blank lines; Space-Left/Right jump to
previous/next word ends (`ge`/`e`).

The Git/Graph horizontal divider is draggable, as are the existing vertical pane
boundaries. Both right panes share their column width. Sticky context shows at
most two lines; indentation guides stay muted except for the current scope.
Scrollbars appear only when content overflows, with search and error/warning
markers. They support the floating workspace panes and can be dragged directly.
Scrollbar updates pause while Telescope is open to avoid switching window context
during prompt editing, and resume after the picker closes.

Resize the framed panes by dragging a shared vertical border. Standard `Ctrl-w >`
and `Ctrl-w <` widen or narrow the focused pane; a preceding count changes more
columns at once. `Ctrl-w =` equalizes visible pane widths. The editor trades width
with the Git sidebar, or the Files sidebar when Git is hidden. Sidebar widths are
retained across focus changes and sidebar toggles within the current session.
Typed `:vertical resize N`, `:vertical resize +N`, and `:vertical resize -N` also
set or adjust the current pane's width.
Animated notifications stack upward from the bottom right.

## Windows terminals

`configs/wezterm/.wezterm.lua` and `configs/alacritty/*.toml` preserve the Windows
settings, including WSL startup, font, spacing, keys, and imported OneHalf palettes.
They are snapshots; the Linux installer deliberately does not replace Windows files.

`configs/windows-terminal/settings.json` snapshots Windows Terminal settings.
The Ubuntu profile allows application titles, and the window uses its active tab's
title so Neovim's project and filename remain visible in Alt-Tab. Its active Store
installation uses `AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`.

To apply a reviewed update from WSL, set `terminal_user_dir` to the Windows profile
path, back up the existing files, then copy all imported Alacritty palettes together:

```bash
terminal_user_dir=/mnt/c/Users/JamesJJStankowicz
terminal_backup_dir=$(mktemp -d "$terminal_user_dir/terminal-backup.XXXXXXXX")
cp "$terminal_user_dir/.wezterm.lua" "$terminal_backup_dir/"
cp -a "$terminal_user_dir/AppData/Roaming/alacritty" "$terminal_backup_dir/"
cp configs/wezterm/.wezterm.lua "$terminal_user_dir/.wezterm.lua"
cp configs/alacritty/*.toml "$terminal_user_dir/AppData/Roaming/alacritty/"
```

## Validation

Shell syntax can be checked without running the installer:

```bash
bash -n bin/install.sh lib/config.sh lib/tools.sh
```

Installer checks run against a temporary `HOME` and preserve existing configuration
files, directories, and broken links. They also check Codex document copies,
backups and repeated installation in default and custom Codex homes, and acceptance
or rejection of download checksums, without network access:

```bash
bash tests/installer.sh
bash tests/installer-workflow.sh
```

To include real binary downloads and version checks:

```bash
bash tests/installer.sh --download
```

The optional check installs the managed binaries in a temporary home, restores
plugins and language tools, and checks workspace, theme, and math integration.
It tests restoring a changed plugin revision, preserving the generated Markdown
bridge on reruns, and reporting a failed preview binary download. It requires
network access, GCC, Make, Git, curl, tar, gzip, and unzip. Both test modes preserve
the working copy's lockfile and avoid sudo/system package installation. Shell
rerun behavior is exercised with isolated fixtures and mocked clone commands in
`tests/installer-workflow.sh`.

Neovim checks require the installed plugin versions and Neovim 0.11.7 or newer.
Run from the repository with the correct Neovim executable first in `PATH`:

```bash
nvim --headless -u NONE -l configs/nvim/tests/theme.lua
nvim --headless -u NONE -c 'luafile configs/nvim/tests/workspace.lua'
nvim --headless -c 'luafile configs/nvim/tests/workspace-integration.lua'
nvim --headless -c 'luafile configs/nvim/tests/git-integration.lua'
nvim --headless -c 'luafile configs/nvim/tests/reading-integration.lua'
nvim --headless -n -c 'luafile configs/nvim/tests/math-integration.lua'
nvim --headless -n -c 'luafile configs/nvim/tests/theme-integration.lua'
nvim --headless -c 'luafile configs/nvim/tests/outline-integration.lua'
nvim --headless -n -c 'luafile configs/nvim/tests/search-integration.lua'
```

The first two checks cover theme refresh and split-command handling. The active
configuration checks exercise actual sidebar plugins, neighboring-buffer closure,
resize, Git polling, Diffview return, and floating Lazygit. They read configuration
files and create their Git fixture outside the repository. Markdown browser checks
are documented in `configs/nvim/markdown-preview/README.md`.
