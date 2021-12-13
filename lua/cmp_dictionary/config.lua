local M = {}

M.default = {
    exact = 2,
    async = false,
    capacity = 5,
    debug = false,
    dic = { ["*"] = {} },
}
M.config = {}

function M.setup(opt)
    if opt then
        M.config = vim.tbl_deep_extend("keep", opt, M.default)
    end
end

function M.get(name)
    return M.config[name]
end

function M.is_setup()
    if vim.tbl_isempty(M.config) then
        return false
    end
    return true
end

return M
