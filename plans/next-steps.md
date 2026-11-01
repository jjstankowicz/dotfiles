# Next steps

## Priority

- [x] Safe, complete installer

## Backlog

### Safe, complete installer

Make the existing Linux/WSL installer repeatable on an established machine.

- [x] Preserve shell customizations and replaced configuration files.
- [x] Install verified editor binaries, Node/npm, and Lazygit on x86_64 and ARM64.
- [x] Restore pinned plugins, build hooks, configured parsers, and Pyright.
- [x] Validate fresh installation, repeat installation, and failure reporting.
- [x] Review the completed change before committing or installing on the host.

Fonts, Windows terminal snapshots, credentials, and optional language-specific
formatters remain separate. Package-manager execution on Amazon Linux/Arch and
ARM64 binary execution require validation on those platforms.
