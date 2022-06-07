local bit=require('bit')
local stack = {}

local function pop()
    return table.remove(stack)
end

local function push(value)
    table.insert(stack, value)
end

local operatorFunc= {}
--[[ Basic Arithmetic ]]
operatorFunc[ [[+]] ]     = function() push(pop() + pop()) end  -- Addtion
operatorFunc[ [[-]] ]     = function() push(-pop() + pop()) end -- Subtraction
operatorFunc[ [[*]] ]     = function() push(pop() * pop()) end  -- Multiplication
operatorFunc[ [[/]] ]     = function() push(1 / pop()*pop()) end  -- Division
operatorFunc[ [[div]] ]   = function() local r=1 / pop() * pop(); push(r>=0 and math.floor(r) or math.ceil(r)) end -- Integer part of division
operatorFunc[ [[%]] ]     = function() local x=pop(); local y=pop(); push(y % x) end  -- Modulus
operatorFunc[ [[abs]] ]   = function() push(math.abs(pop())) end  -- Absolute Value
operatorFunc[ [[chs]] ]   = function() push(-pop()) end  -- Change Sign
--[[ Rounding ]]
operatorFunc[ [[floor]] ] = function() push(math.floor(pop())) end  -- Floor - round down to nearest integer
operatorFunc[ [[ceil]] ]  = function() push(math.ceil(pop())) end  -- Ceiling - round up to nearest integer
operatorFunc[ [[round]] ] = function() local x=pop(); push(x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)) end -- Round to nearest integer
operatorFunc[ [[trunc]] ] = function() local r=pop(); push(r>=0 and math.floor(r) or math.ceil(r)) end -- Round toward zero
--[[ Powers & Logs ]]
operatorFunc[ [[exp]] ]   = function() push(math.exp(pop())) end -- Raise e to the x power
operatorFunc[ [[log]] ]   = function() push(math.log(pop())) end -- Natural log of x
operatorFunc[ [[logx]] ]  = function() local x=pop(); push(math.log(pop(),x)) end -- Log y of x
operatorFunc[ [[log10]] ] = function() push(math.log(pop(),10)) end -- Log (base 10) of x
operatorFunc[ [[log2]] ]  = function() push(math.log(pop(),2) )end -- Log (base 2) of x
operatorFunc[ [[sqrt]] ]  = function() push(math.sqrt(pop())) end -- Square Root
operatorFunc[ [[**]] ]    = function() local x=pop(); local y=pop(); push(y ^ x) end  -- Exponentiation
operatorFunc[ [[\]] ]     = function() push(1 / pop()) end -- Reciprocal
--[[ Trigonometry ]]
operatorFunc[ [[deg]] ]   = function() push(math.deg(pop())) end -- convert x to degrees
operatorFunc[ [[rad]] ]   = function() push(math.rad(pop())) end -- convert x to radians

operatorFunc[ [[sin]] ]   = function() push(math.sin(pop())) end -- Sine
operatorFunc[ [[cos]] ]   = function() push(math.cos(pop())) end -- Cosine
operatorFunc[ [[tan]] ]   = function() push(math.tan(pop())) end -- Tangent
operatorFunc[ [[csc]] ]   = function() push(1 / math.sin(pop())) end -- Sine
operatorFunc[ [[sec]] ]   = function() push(1 / math.cos(pop())) end -- Cosine
operatorFunc[ [[cot]] ]   = function() push(1 / math.tan(pop())) end -- Tangent

operatorFunc[ [[asin]] ]  = function() push(math.asin(pop())) end -- Inverse sine
operatorFunc[ [[acos]] ]  = function() push(math.acos(pop())) end -- Inverse cosine
operatorFunc[ [[atan]] ]  = function() push(math.atan(pop())) end -- Inverse Tangent
operatorFunc[ [[acsc]] ]  = function() push(math.asin(1 / pop())) end -- Inverse cosecant
operatorFunc[ [[asec]] ]  = function() push(math.acos(1 / pop())) end -- Inverse secant
operatorFunc[ [[acot]] ]  = function() push(math.atan(1 / pop())) end -- Inverse cotangent

operatorFunc[ [[sinh]] ]  = function() local x=pop(); push((math.exp(x) - math.exp(-x)) / 2) end -- Hyperbolic sine
operatorFunc[ [[cosh]] ]  = function() local x=pop(); push((math.exp(x) - math.exp(-x)) / 2) end -- Hyperbolic cosine
operatorFunc[ [[tanh]] ]  = function() local x=pop(); push((math.exp(2*x)-1) / (math.exp(2*x)+1)) end -- Hyperbolic tangent
operatorFunc[ [[asinh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x+1))) end -- Inverse hyperbolic sine
operatorFunc[ [[acosh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x-1))) end -- Inverse hyperbolic cosine
operatorFunc[ [[atanh]] ] = function() local x=pop(); push(math.log((1+x) / (1-x)) / 2) end -- Inverse hyperbolic tangent

operatorFunc[ [[csch]] ]  = function() local x=pop(); push(2 / (math.exp(x) - math.exp(-x))) end -- Hyperbolic cosecant
operatorFunc[ [[sech]] ]  = function() local x=pop(); push(2 / (math.exp(x) + math.exp(-x))) end -- Hyperbolic secant
operatorFunc[ [[coth]] ]  = function() local x=pop(); push((math.exp(2*x)+1) / (math.exp(2*x)-1)) end -- Hyperbolic cotangent
operatorFunc[ [[acsch]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1+x*x)) / x)) end -- Inverse hyperbolic sosecant
operatorFunc[ [[asech]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1-x*x)) / x)) end -- Inverse hyperbolic secant
operatorFunc[ [[acoth]] ] = function() local x=pop(); push(math.log((x+1) / (x-1)) / 2) end -- Inverse hyperbolic cotangent

--[[ Bitwise ]]
operatorFunc[ [[&]] ]     = function() push(bit.band(pop(),pop())) end -- AND
operatorFunc[ [[|]] ]     = function() push(bit.bor(pop(),pop())) end -- OR
operatorFunc[ [[^]] ]     = function() push(bit.bxor(pop(),pop())) end -- XOR
operatorFunc[ [[~]] ]     = function() push(bit.bnot(pop())) end -- NOT
operatorFunc[ [[<<]] ]    = function() local n=pop(); push(bit.lshift(pop(),n)) end -- Left Shift
operatorFunc[ [[>>]] ]    = function() local n=pop(); push(bit.rshift(pop(),n)) end -- Right Shift
--[[ Constants ]]
operatorFunc[ [[pi]] ]    = function() push(math.pi) end -- 3.141592653....
operatorFunc[ [[e]] ]     = function() push(math.exp(1)) end -- 2.718281828...
operatorFunc[ [[phi]] ]   = function() push((1+math.sqrt(5)) / 2) end -- 1.618033989...
--[[ Other ]]
operatorFunc[ [[hrs]] ]   = function() push((pop() / 60 + pop()) / 60 + pop()) end -- Convert Z:Y:X to hours
operatorFunc[ [[hms]] ]   = function() local x=pop(); for _=1,2 do local t=x<0 and math.ceil(x) or math.floor(x); push(x); x=60*(x-t); end; push(x) end -- Convert X hours to Z:Y:X


-- Get all unique characters from the operatorFunc keys. These characters will
-- trigger completion to begin on this source.
local function contains(table, val)
   for i=1,#table do
      if table[i] == val then
         return true
      end
   end
   return false
end

local triggerCharacters = {' ', '', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', 'E', 'e'}
for op,_ in pairs(operatorFunc) do
    for char in string.gmatch(op, '.') do
        if not contains(triggerCharacters, char) then
            triggerCharacters[#triggerCharacters+1] = char
        end
    end
end
-- print(vim.inspect(triggerCharacters))

-- Create the regex that will determine if the text leading up to the cursor is
-- a valid RPN expression. The regex, paraphrased, is:
--  number ( space ( number | operator ) ) +
local operators = {}
for op,_ in pairs(operatorFunc) do
    operators[#operators+1] = vim.fn.escape(op, [[~^*/\]] )
end

local numberRegex = [[\([+-]\?\(0\|0\?\.\d\+\|[1-9]\d*\(\.\d\+\)\?\)\([Ee][+-]\?\d\+\)\?\)]]
local expressionRegex = table.concat(operators,[[\|]])  -- Join all operators
expressionRegex = [[\(]] .. numberRegex .. [[\|]] .. expressionRegex .. [[\)]]  -- Add a number pattern to the mix.
expressionRegex = [[\(\(^\|\s\+\)]] .. expressionRegex .. [[\)\+]]  -- Multiple space-delimited operators or numbers.
expressionRegex = [[\%#=1]] .. expressionRegex  -- Regex options: engine #1
-- print(expressionRegex)

-- source contains the callback functions that are needed to work in nvim-cmp.
local source = {}
source.new = function()
    return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
    return triggerCharacters
end

source.complete = function(_, request, callback)
    local input = request.context.cursor_before_line
    print('original input--->',input,'<-----------------------------------------------------------')
    local s,e = vim.regex(expressionRegex):match_str(input)
    -- print('s: ',s,'   e: ',e)
    if not s or not e then
        return callback()
    end
    input = string.sub(input, s+1)
    -- print('trimmed input: ',input)

    stack = {}
    for word in string.gmatch(input, "%g+") do
        -- print('word: ',word)
        local number = tonumber(word)
        if number then
            push(number)
        else
            local f = operatorFunc[word]
            local ok,_ = pcall(f)
            if not ok then
                return callback()
            end
        end
        -- print('stack: ',vim.inspect(stack))
    end
    local value = ''
    -- print('value: ',value)
    for _,n in ipairs(stack) do
        value = string.gsub(value .. ' ' .. n, "^%s*(.-)%s*$", "%1")
    -- print('value: ',value)
    end
    -- print('value: ',value)
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    local r =
        {
            items = {{
                word = input,
                label = value,
                textEdit = {
                    range = {
                        start = { line = request.context.cursor.row-1, character = s, },
                        ['end'] = { line = request.context.cursor.row-1, character = request.context.cursor.col-1, }, },
                    newText = value },
            },{
                word = input .. ' ▶ ' .. value,
                label = input .. ' ▶ ' .. value,
                textEdit = {
                    range = {
                        start = { line = request.context.cursor.row-1, character = s, },
                        ['end'] = { line = request.context.cursor.row-1, character = request.context.cursor.col-1, }, },
                    newText = input .. ' ▶ ' .. value },
            },},
        }
    print('r', vim.inspect(r))
    callback(r)
end

return source
