local M = {}

M.default = {
    dic = {
        ["*"] = {},
        filename = nil,
        filepath = nil,
        spelllang = nil,
    },
    exact = 2,
    first_case_insensitive = false,
    document = false,
    document_command = "wn %s -over",
    async = false,
    max_items = -1,
    capacity = 5,
    debug = false,
}
M.config = {}
M.ready = false

local function normalize_paths(paths)
    if type(paths) == "string" then
        return { paths }
    end
    return paths
end

local function tbl_copy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    local copy = {}
    for i, v in pairs(tbl) do
        copy[i] = v
    end
    return copy
end

local function split_by_comma_of_keys(dic)
    for key, value in pairs(dic) do
        if key:find(",") then
            for k in vim.gsplit(key, ",") do
                dic[k] = tbl_copy(value)
            end
            dic[key] = nil
        end
    end
    return dic
end

function M.setup(opt)
    vim.validate({
        opt = { opt, "table" },
        ["opt.dic"] = { opt.dic, "t" },
    })

    opt.dic = split_by_comma_of_keys(opt.dic)

    for fts, paths in pairs(opt.dic) do
        if vim.tbl_contains({ "filename", "filepath", "spelllang" }, fts) then
            opt.dic[fts] = vim.tbl_map(normalize_paths, split_by_comma_of_keys(paths))
        else
            opt.dic[fts] = normalize_paths(paths)
        end
    end

    M.config = vim.tbl_deep_extend("keep", opt, M.default)

    local c = assert(M.config)
    vim.validate({
        dic = { c.dic, "t" },
        ["dic.*"] = { c.dic["*"], "t", true },
        ["dic.filename"] = { c.dic.filename, "t", true },
        ["dic.filepath"] = { c.dic.filepath, "t", true },
        ["dic.spelllang"] = { c.dic.spelllang, "t", true },
        exact = { c.exact, "n" },
        first_case_insensitive = { c.first_case_insensitive, "b" },
        document = { c.document, "b" },
        document_command = { c.document_command, { "s", "t" } },
        async = { c.async, "b" },
        max_items = { c.max_items, "n" },
        capacity = { c.capacity, "n" },
        debug = { c.debug, "b" },
    })

    M.ready = true
end

function M.get(name)
    return M.config[name]
end

return M
