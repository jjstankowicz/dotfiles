# Markdown source navigation

Open a Markdown file and press Space-mv. Double-click a rendered heading,
paragraph, list item, or table to move Neovim to the corresponding source
block. The browser briefly outlines the block after a successful jump.
The cursor moves in Neovim; operating-system focus stays in the browser.

`lua/markdown_source.lua` patches the installed markdown-preview.nvim server
and exported HTML whenever Lazy loads the plugin. The patch uses the existing
WebSocket and prebuilt binary; it needs no Node dependencies or frontend build.
Its tracked source is reapplied after plugin reinstalls and updates. If the
upstream file layout changes, setup reports a warning instead of guessing where
to insert the patch.

The preview supplies zero-based source positions for blocks, not individual
words or wrapped lines. Elements without a source position do not jump.
Links and interactive controls keep their usual behavior. Navigation uses an
existing editing window displaying the Markdown buffer, including the framed
editor; a hidden or
deleted buffer does not replace another file or a sidebar.

The integration test in `../tests/source-navigation.cjs` uses the active Neovim
configuration and Playwright Chromium. `PLAYWRIGHT_MODULE` can select an existing
Playwright installation; `CHROMIUM_PATH` can select an existing Chromium binary.
