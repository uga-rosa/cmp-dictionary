local M = {}

M.default = {
    dic = {
        ["*"] = {},
        filename = nil,
        filepath = nil,
    },
    exact = 2,
    first_case_insensitive = false,
    async = false,
    capacity = 5,
    debug = false,
}
M.config = {}
M.ready = false

function M.setup(opt)
    vim.validate({
        opt = { opt, "table" },
    })

    for fts, paths in pairs(opt.dic) do
        if string.find(fts, ",") then
            for ft in vim.gsplit(fts, ",") do
                opt.dic[ft] = paths
            end
            opt.dic[fts] = nil
        end
    end

    M.config = vim.tbl_deep_extend("keep", opt, M.default)
    M.ready = true
end

function M.get(name)
    return M.config[name]
end

return M
