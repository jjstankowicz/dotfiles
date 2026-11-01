/* Integration test: real browser -> preview WebSocket -> Neovim editor pane. */
const assert = require('node:assert/strict')
const fs = require('node:fs')
const os = require('node:os')
const path = require('node:path')
const { spawn, execFileSync } = require('node:child_process')
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright')

async function main() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'markdown-bridge-'))
  const socket = path.join(directory, 'nvim.sock')
  const urlFile = path.join(directory, 'url')
  const document = path.join(directory, 'sample.md')
  fs.writeFileSync(document, [
    '# Source navigation', '',
    'First paragraph.', '',
    'Second paragraph with $x^2$ inline math.', '',
    '- Parent item', '  - Nested item', '',
    '## Last heading', '',
    '[Example link](https://example.com)', '',
    '| A | B |', '| - | - |', '| 1 | 2 |', ''
  ].join('\n'))
  const bootstrap = path.join(directory, 'start.lua')
  fs.writeFileSync(bootstrap, `
vim.g.mkdp_auto_close = 0
vim.g.mkdp_browserfunc = 'MarkdownBridgeTestOpen'
vim.cmd [[
function! MarkdownBridgeTestOpen(url) abort
  call writefile([a:url], $MARKDOWN_BRIDGE_URL)
endfunction
]]
vim.defer_fn(function() vim.cmd('MarkdownPreview') end, 500)
`)
  let logs = ''
  const nvim = spawn('nvim', ['--headless', '--listen', socket, document, '-c', `luafile ${bootstrap}`], {
    env: { ...process.env, MARKDOWN_BRIDGE_URL: urlFile }
  })
  nvim.stderr.on('data', data => { logs += data })
  nvim.stdout.on('data', data => { logs += data })
  let browser
  const evaluate = code => JSON.parse(execFileSync('nvim', [
    '--server', socket, '--remote-expr',
    `luaeval(${JSON.stringify(`vim.json.encode((function() ${code} end)())`)})`
  ], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }))
  try {
    for (let attempt = 0; attempt < 100 && !fs.existsSync(urlFile); attempt++) {
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    assert(fs.existsSync(urlFile), `Preview failed to start: ${logs}`)
    const url = fs.readFileSync(urlFile, 'utf8').trim()
    browser = await chromium.launch({
      headless: true,
      ...(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {})
    })
    const page = await browser.newPage()
    await page.goto(url)
    await page.waitForSelector('[data-source-line="4"] .katex')
    await page.waitForFunction(() => window.socket && window.socket.connected)
    const original = evaluate('return vim.api.nvim_buf_get_lines(0, 0, -1, false)')
    const paneQuery = 'return require("framed_layout").panes()'
    const windows = evaluate(paneQuery)
    assert.equal(windows.length, 5, 'Expected the configured five-pane layout')
    const editor = evaluate('return vim.api.nvim_get_current_win()')
    for (const line of [4, 7, 9, 13, 0]) {
      evaluate(`vim.api.nvim_set_current_win(${windows.find(window => window !== editor)}); return true`)
      await page.locator(`[data-source-line="${line}"]`).first().dblclick()
      for (let attempt = 0; attempt < 50; attempt++) {
        if (evaluate('return vim.api.nvim_get_current_win()') === editor &&
            evaluate('return vim.api.nvim_win_get_cursor(0)[1]') === line + 1) break
        await new Promise(resolve => setTimeout(resolve, 100))
      }
      assert.equal(evaluate('return vim.api.nvim_win_get_cursor(0)[1]'), line + 1)
      assert.equal(evaluate('return vim.api.nvim_get_current_win()'), editor)
      assert.deepEqual(evaluate(paneQuery), windows)
    }
    for (const value of [-1, 2.5, '4', null]) {
      const jumped = await page.evaluate(value => new Promise(resolve => {
        window.socket.emit('jump_to_source', value, resolve)
      }), value)
      assert.equal(jumped, false, 'Invalid source line was accepted')
    }
    assert.equal(evaluate('return vim.api.nvim_win_get_cursor(0)[1]'), 1)
    assert.deepEqual(evaluate('return vim.api.nvim_buf_get_lines(0, 0, -1, false)'), original)
    const plugin = evaluate('return require("lazy.core.config").plugins["markdown-preview.nvim"].dir')
    const server = fs.readFileSync(path.join(plugin, 'app/server.js'), 'utf8')
    const html = fs.readFileSync(path.join(plugin, 'app/out/index.html'), 'utf8')
    evaluate(`require('markdown_source').setup(${JSON.stringify(plugin)}); return true`)
    assert.equal(fs.readFileSync(path.join(plugin, 'app/server.js'), 'utf8'), server)
    assert.equal(fs.readFileSync(path.join(plugin, 'app/out/index.html'), 'utf8'), html)
    console.log('PASS: browser source navigation, math, nested lists, tables, pane preservation, validation, and idempotent installation')
  } finally {
    if (browser) await browser.close()
    if (fs.existsSync(socket)) {
      try { evaluate('vim.cmd("qa!"); return true') } catch (_) { /* RPC closes on exit. */ }
    }
    nvim.kill()
    fs.rmSync(directory, { recursive: true, force: true })
    if (logs.includes('Error detected') || logs.includes('unhandledRejection')) {
      throw new Error(logs)
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1 })
