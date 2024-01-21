local M = {}

---@param command string[]
---@return string[] result
function M.system(command)
  if vim.system then
    local result = vim.system(command, { text = true }):wait()
    return vim.split(result.stdout or "", "\n")
  else
    local ok, Job = pcall(require, "plenary.job")
    if not ok then
      vim.notify_once(
        "[cmp-dictionary] Neither vim.system() nor plenary.nvim",
        vim.log.levels.ERROR
      )
      return {}
    end
    local job = Job:new({
      command = command[1],
      args = vim.list_slice(command, 2),
    }):wait()
    if not job then
      return {}
    end
    return job:result()
  end
end

return M
