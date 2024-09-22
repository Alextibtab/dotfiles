return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'rcarriga/nvim-dap-ui',
      'mfussenegger/nvim-dap-python',
      'theHamsta/nvim-dap-virtual-text',
      'williamboman/mason.nvim',
    },
    config = function()
      local dap = require 'dap'
      local ui = require 'dapui'

      require('dapui').setup()
      require('dap-python').setup()

      dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = '/home/tibtab/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
      }

      dap.configurations.cpp = {
        {
          name = 'Launch File',
          type = 'cppdbg',
          request = 'launch',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopAtEntry = true,
        },
        {
          name = 'Attach to gdbserver :1234',
          type = 'cppdbg',
          request = 'launch',
          MIMode = 'gdb',
          miDebuggerServerAddress = 'localhost:1234',
          miDebuggerPath = '/usr/bin/gdb',
          cwd = '${workspaceFolder}',
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
        },
      }

      dap.configurations.c = dap.configurations.cpp
      dap.configurations.rust = dap.configurations.cpp

      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'dap: toggle breakpoint' })
      vim.keymap.set('n', '<leader>dgb', dap.run_to_cursor, { desc = 'dap: run to breakpoint' })

      vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'dap: continue' })
      vim.keymap.set('n', '<leader>di', dap.step_into, { desc = 'dap: step into' })
      vim.keymap.set('n', '<leader>do', dap.step_over, { desc = 'dap: step over' })
      vim.keymap.set('n', '<leader>dso', dap.step_out, { desc = 'dap: step out' })
      vim.keymap.set('n', '<leader>dsb', dap.step_back, { desc = 'dap: step back' })
      vim.keymap.set('n', '<leader>dx', dap.restart, { desc = 'dap: restart' })

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
