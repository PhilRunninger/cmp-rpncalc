local rpn = require('cmp_rpncalc.rpn')

local function changeBase(num)
    if type(num) == 'string' then return num end

    local sign = num < 0 and '-' or ''
    if rpn.base == 10 then return string.format('%s', num) end
    if rpn.base == 16 then return string.format('%s0x%x', sign, math.abs(num)) end
    if rpn.base == 2 then
        num = math.floor(math.abs(num))
        local bits = math.max(1, select(2, math.frexp(num)))
        local t={}
        for b = bits,1,-1 do
            t[b] = math.fmod(num,2)
            num = math.floor((num-t[b]) / 2)
        end
        return string.format('%s0b%s', sign, table.concat(t))
    end
end

-- source contains the callback functions that are needed to work in nvim-cmp.
local M = {}

M.new = function()
    return setmetatable({}, { __index = M })
end

M.get_trigger_characters = function()
    return rpn.triggerCharacters()
end

M.complete = function(_, request, callback)
    rpn.init()

    -- vim.print(request)
    local input = request.context.cursor_before_line
    local s,e = vim.regex(rpn.expressionRegex()):match_str(input)
    -- vim.print(s,e,input)
    if not s or not e then
        return callback({})
    end
    input = string.sub(input, s+1)
    -- vim.print(s,e,input)

    for _,word in ipairs(vim.fn.split(input, ' \\+')) do
        local number = tonumber(word)
        -- vim.print(word)
        if number then
            rpn.push(number)
            rpn.lastx = rpn.stack[#rpn.stack]
        elseif word:match('.+,.+') then
            local c = vim.fn.split(word, ',')
            rpn.push({tonumber(c[1]), tonumber(c[2])})
            rpn.lastx = rpn.stack[#rpn.stack]
        else
            local f = rpn.op[word]
            local ok,_ = pcall(f)
            if not ok then
                return callback({})
            end
        end
        -- vim.print(stack)
    end

    local value = ''
    for _,n in ipairs(rpn.stack) do
        if math.isNan(n) then
            value = value .. ' NaN'
        elseif math.isPosInf(n) then
            value = value .. ' Infinity'
        elseif math.isNegInf(n) then
            value = value .. ' -Infinity'
        elseif math.isComplex(n) then
            if math.isNan(n[1]) or math.isNan(n[2]) then
                value = value .. ' NaN'
            elseif math.isPosInf(n[1]) or math.isPosInf(n[2]) then
                value = value .. ' Infinity'
            elseif math.isNegInf(n[1]) or math.isNegInf(n[2]) then
                value = value .. ' -Infinity'
            else
                value = value .. ' ' .. changeBase(n[1]) .. (n[2] >= 0 and '+' or '') .. changeBase(n[2]) .. 'i'
            end
        elseif math.isReal(n) then
            value = value .. ' ' .. changeBase(n)
        else
            value = value .. ' ' .. 'Error'
        end
    end
    value = string.gsub(value, "^%s*(.-)%s*$", "%1")
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    local items = {
        {
            label = input .. ' == ' .. value,
            filterText = input,
            textEdit = {
                range = {
                    start = { line = request.context.cursor.row-1, character = s, },
                    ['end'] = { line = request.context.cursor.row-1, character = request.context.cursor.col-1, }, },
                newText = input .. ' == ' .. value
            },
        },
        {
            label = value,
            filterText = input,
            textEdit = {
                range = {
                    start = { line = request.context.cursor.row-1, character = s, },
                    ['end'] = { line = request.context.cursor.row-1, character = request.context.cursor.col-1, }, },
                newText = value
            },
        },
    }

    callback({ items = items, isIncomplete = true })
end

return M
