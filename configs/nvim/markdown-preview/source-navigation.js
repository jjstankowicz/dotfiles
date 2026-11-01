/* Double-click a rendered Markdown block to locate its source in Neovim. */
(() => {
  document.addEventListener('dblclick', (event) => {
    const target = event.target instanceof Element ? event.target : null
    if (!target || target.closest('a, button, input, textarea, select')) return
    const block = target.closest('[data-source-line]')
    const socket = window.socket
    if (!block || !socket || !socket.connected) return
    const value = block.getAttribute('data-source-line')
    if (!/^\d+$/.test(value)) return
    const line = Number(value)
    if (!Number.isSafeInteger(line)) return
    socket.emit('jump_to_source', line, (jumped) => {
      if (!jumped) return
      block.animate(
        [{ outline: '2px solid #8888' }, { outline: '2px solid transparent' }],
        { duration: 700 }
      )
    })
  })
})()
