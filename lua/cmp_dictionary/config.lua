local M = {}

M.default = {
    exact = 2,
    async = false,
    capacity = 5,
    debug = false,
    dic = { ["*"] = {} },
}
M.config = {}
M.ready = false

function M.setup(opt)
    vim.validate({
        opt = { opt, "table" },
    })
    M.config = vim.tbl_deep_extend("keep", opt, M.default)
    M.ready = true
end

function M.get(name)
    return M.config[name]
end

return M
