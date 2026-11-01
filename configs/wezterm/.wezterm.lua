local wezterm = require 'wezterm'

local function scheme_for(appearance)
  if appearance:find("Dark") then
    return "OneHalfDark"
  else
    return "OneHalfLight"
  end
end

return {
  default_domain = "WSL:Ubuntu",
  font = wezterm.font_with_fallback({ "CaskaydiaCove NF", "Hack NF" }),
  font_size = 16.0,
  line_height = 1.08,
  color_scheme = scheme_for(wezterm.gui.get_appearance()),
  -- enable_wayland = false,
  -- window_decorations = "RESIZE",
  window_padding = { left = 4, right = 4, top = 2, bottom = 2 },
  hide_tab_bar_if_only_one_tab = true,
  -- use_fancy_tab_bar = false,
  scrollback_lines = 5000,

  keys = {
    { key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
    { key = "c", mods = "CTRL", action = wezterm.action.CopyTo("Clipboard") },
    { key = "Enter", mods = "ALT", action = "ToggleFullScreen" },
    { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  },

  audible_bell = "Disabled",

}
