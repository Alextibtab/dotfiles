return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    event = 'InsertEnter',
    opts = {
      suggestion = { enabled = false },
      auto_trigger = true,
      keymap = {
        accept = false,
      },
    },
    panel = { enabled = false },
  },
}
