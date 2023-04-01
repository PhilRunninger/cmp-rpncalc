local bit=require('bit')
local stack = {}

local function pop()
    return table.remove(stack)
end

local function push(value)
    table.insert(stack, value)
end

math.isreal = function(x) return type(x) == 'number' end
math.iscomplex = function(x) return type(x) == 'table' and #x == 2 and type(x[1]) == 'number' and type(x[2]) == 'number' end
math.round = function(x) return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5) end -- Round to nearest integer
math.trunc = function(x) return x>=0 and math.floor(x) or math.ceil(x) end -- Round toward zero

local op= {}

-- Basic Arithmetic --------------------------------------------------------------------------------
op[ [[+]] ] = function()
        local x=pop(); local y=pop();  -- Addtion
        if math.isreal(x)        and math.isreal(y)    then push(x + y)
        elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] + y, x[2]})
        elseif math.isreal(x)    and math.iscomplex(y) then push({x + y[1], y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1] + y[1], x[2] + y[2]})
        end
    end
op[ [[-]] ] = function() local x=pop(); local y=pop();  -- Subtraction
        if math.isreal(x)        and math.isreal(y)    then push(y - x)
        elseif math.iscomplex(x) and math.isreal(y)    then push({y - x[1], -x[2]})
        elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] - x, y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({y[1] - x[1], y[2] - x[2]})
        end
    end
op[ [[*]] ] = function() local x=pop(); local y=pop();  -- Multiplication
        if math.isreal(x)        and math.isreal(y)    then push(x * y)
        elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] * y, x[2] * y})
        elseif math.isreal(x)    and math.iscomplex(y) then push({x * y[1], x * y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1]*y[1] - x[2]*y[2], x[1]*y[2] + x[2]*y[1]})
        end
    end
op[ [[/]] ] = function() local x=pop(); local y=pop();  -- Division
        if     math.isreal(x)    and math.isreal(y)    then push(y / x)
        elseif math.iscomplex(x) and math.isreal(y)    then push({y*x[1]/(x[1]*x[1] + x[2]*x[2]), -y*x[2]/(x[1]*x[1] + x[2]*x[2])})
        elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] / x, y[2] / x})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({(y[1]*x[1]+y[2]*x[2]) / (x[1]*x[1]+x[2]*x[2]), (y[2]*x[1]-y[1]*x[2]) / (x[1]*x[1]+x[2]*x[2])})
        end
    end
op[ [[div]] ]   = function() local r=1 / pop() * pop(); push(math.trunc(r)) end -- Integer part of division
op[ [[%]] ]     = function() local x=pop(); local y=pop(); push(y % x) end  -- Modulus
op[ [[abs]] ]   = function() local x=pop();  -- Absolute Value
        if math.isreal(x)        then push(math.abs(x))
        elseif math.iscomplex(x) then push(math.sqrt(x[1]*x[1] + x[2]*x[2]))
        end
    end
op[ [[arg]] ]   = function() local x=pop();  -- Arg
        if math.isreal(x)        then push('nan')
        elseif math.iscomplex(x) then push(math.atan2(x[2], x[1]));
        end
    end
op[ [[chs]] ]   = function() local x=pop();  -- Change Sign
        if math.isreal(x)        then push(-x)
        elseif math.iscomplex(x) then push({-x[1], -x[2]})
        end
    end

-- Rounding --------------------------------------------------------------------------------
op[ [[floor]] ] = function() local x = pop();  -- Floor - round down to nearest integer
        if math.isreal(x)        then push(math.floor(x))
        elseif math.iscomplex(x) then push({math.floor(x[1]), math.floor(x[2])})
        end
    end
op[ [[ceil]] ]  = function() local x = pop();  -- Ceiling - round up to nearest integer
        if math.isreal(x)        then push(math.ceil(x))
        elseif math.iscomplex(x) then push({math.ceil(x[1]), math.ceil(x[2])})
        end
    end
op[ [[round]] ] = function() local x = pop();  -- Round to nearest integer
        if math.isreal(x)        then push(math.round(x))
        elseif math.iscomplex(x) then push({math.round(x[1]), math.round(x[2])})
        end
    end
op[ [[trunc]] ] = function() local x = pop();  -- Round toward zero
        if math.isreal(x)        then push(math.trunc(x))
        elseif math.iscomplex(x) then push({math.trunc(x[1]), math.trunc(x[2])})
        end
    end

-- Powers & Logs --------------------------------------------------------------------------------
op[ [[log]] ]   = function() local x = pop(); -- Natural log of x
        if math.iscomplex(x) then
            local r = math.sqrt(x[1]*x[1] + x[2]*x[2])
            local theta = math.atan2(x[2],x[1])
            push({math.log(r), theta})
        elseif math.isreal(x) then
            push(math.log(x))
        end
    end
op[ [[log10]] ] = function() pcall(op[ [[log]] ]); push(10); pcall(op[ [[log]] ]); pcall(op[ [[/]] ]) end -- Log (base 10) of x
op[ [[log2]] ] = function() pcall(op[ [[log]] ]); push(2); pcall(op[ [[log]] ]); pcall(op[ [[/]] ]) end -- Log (base 2) of x
op[ [[logx]] ]  = function() local x=pop(); pcall(op[ [[log]] ]); push(x); pcall(op[ [[log]] ]); pcall(op[ [[/]] ]) end -- Log y of x

op[ [[**]] ] = function() local x=pop(); local y=pop(); -- Exponentiation - y to the x power
        if ((math.iscomplex(y) and y[1]==0 and y[2]==0) or y == 0) and
           ((math.iscomplex(x) and x[1]==0 and x[2]==0) or x == 0) then push('nan')
        elseif ((math.iscomplex(y) and y[1]==0 and y[2]==0) or y == 0) and
               (math.isreal(x) and x < 0) then push('inf')
        elseif math.iscomplex(x) and math.iscomplex(y) then
            local r = math.sqrt(y[1]*y[1] + y[2]*y[2])
            local theta = math.atan2(y[2],y[1])
            local m = math.exp(x[1]*math.log(r) - x[2]*theta)
            push({m*math.cos(x[2]*math.log(r) + x[1]*theta), m*math.sin(x[2]*math.log(r) + x[1]*theta)})
        elseif math.isreal(x) and math.iscomplex(y) then
            local r = math.sqrt(y[1]*y[1]+y[2]*y[2])
            local theta = math.atan2(y[2],y[1])
            push({math.pow(r,x)*math.cos(theta*x), math.pow(r,x)*math.sin(theta*x)})
        elseif math.iscomplex(x) then
            push({math.pow(y,x[1])*math.cos(x[2]*math.log(y)), math.pow(y,x[1])*math.sin(x[2]*math.log(y))})
        elseif y < 0 and x ~= math.round(x) then
            push({y,0})
            push(x)
            pcall(op[ [[**]] ])
        else
            push(y ^ x)
        end
    end
op[ [[exp]] ]   = function() local x = pop(); push(math.exp(1)); push(x); pcall(op[ [[**]] ]) end -- Raise e to the x power
op[ [[\]] ]     = function() push(-1); pcall(op[ [[**]] ]) end -- Reciprocal
op[ [[sqrt]] ]  = function() push(0.5); pcall(op[ [[**]] ]) end -- Square root of x

-- Trigonometry --------------------------------------------------------------------------------
op[ [[deg]] ]   = function() push(math.deg(pop())) end -- convert x to degrees
op[ [[rad]] ]   = function() push(math.rad(pop())) end -- convert x to radians

op[ [[sin]] ]   = function() push(math.sin(pop())) end -- Sine
op[ [[cos]] ]   = function() push(math.cos(pop())) end -- Cosine
op[ [[tan]] ]   = function() push(math.tan(pop())) end -- Tangent
op[ [[csc]] ]   = function() push(1 / math.sin(pop())) end -- Cosecant
op[ [[sec]] ]   = function() push(1 / math.cos(pop())) end -- Secant
op[ [[cot]] ]   = function() push(1 / math.tan(pop())) end -- Cotangent

op[ [[asin]] ]  = function() push(math.asin(pop())) end -- Inverse sine
op[ [[acos]] ]  = function() push(math.acos(pop())) end -- Inverse cosine
op[ [[atan]] ]  = function() push(math.atan(pop())) end -- Inverse Tangent
op[ [[acsc]] ]  = function() push(math.asin(1 / pop())) end -- Inverse cosecant
op[ [[asec]] ]  = function() push(math.acos(1 / pop())) end -- Inverse secant
op[ [[acot]] ]  = function() push(math.atan(1 / pop())) end -- Inverse cotangent

op[ [[sinh]] ]  = function() local x=pop(); push((math.exp(x) - math.exp(-x)) / 2) end -- Hyperbolic sine
op[ [[cosh]] ]  = function() local x=pop(); push((math.exp(x) + math.exp(-x)) / 2) end -- Hyperbolic cosine
op[ [[tanh]] ]  = function() local x=pop(); push((math.exp(2*x)-1) / (math.exp(2*x)+1)) end -- Hyperbolic tangent
op[ [[asinh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x+1))) end -- Inverse hyperbolic sine
op[ [[acosh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x-1))) end -- Inverse hyperbolic cosine
op[ [[atanh]] ] = function() local x=pop(); push(math.log((1+x) / (1-x)) / 2) end -- Inverse hyperbolic tangent

op[ [[csch]] ]  = function() local x=pop(); push(2 / (math.exp(x) - math.exp(-x))) end -- Hyperbolic cosecant
op[ [[sech]] ]  = function() local x=pop(); push(2 / (math.exp(x) + math.exp(-x))) end -- Hyperbolic secant
op[ [[coth]] ]  = function() local x=pop(); push((math.exp(2*x)+1) / (math.exp(2*x)-1)) end -- Hyperbolic cotangent
op[ [[acsch]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1+x*x)) / x)) end -- Inverse hyperbolic cosecant
op[ [[asech]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1-x*x)) / x)) end -- Inverse hyperbolic secant
op[ [[acoth]] ] = function() local x=pop(); push(math.log((x+1) / (x-1)) / 2) end -- Inverse hyperbolic cotangent

-- Bitwise --------------------------------------------------------------------------------
op[ [[&]] ]     = function() push(bit.band(pop(),pop())) end -- AND
op[ [[|]] ]     = function() push(bit.bor(pop(),pop())) end -- OR
op[ [[^]] ]     = function() push(bit.bxor(pop(),pop())) end -- XOR
op[ [[~]] ]     = function() push(bit.bnot(pop())) end -- NOT
op[ [[<<]] ]    = function() local n=pop(); push(bit.lshift(pop(),n)) end -- Left Shift
op[ [[>>]] ]    = function() local n=pop(); push(bit.rshift(pop(),n)) end -- Right Shift

-- Constants --------------------------------------------------------------------------------
op[ [[pi]] ]    = function() push(math.pi) end -- 3.141592653....
op[ [[e]] ]     = function() push(math.exp(1)) end -- 2.718281828...
op[ [[phi]] ]   = function() push((1+math.sqrt(5)) / 2) end -- 1.618033989...
op[ [[i]] ]     = function() push({0,1}) end -- the imaginary unit value

-- Other --------------------------------------------------------------------------------
op[ [[hrs]] ]   = function() push((pop() / 60 + pop()) / 60 + pop()) end -- Convert Z:Y:X to hours
op[ [[hms]] ]   = function() local x=pop(); for _=1,2 do local t=x<0 and math.ceil(x) or math.floor(x); push(t); x=60*(x-t); end; push(x) end -- Convert X hours to Z:Y:X

-- Get all unique characters from the op keys. These characters will
-- trigger completion to begin on this source.
local function contains(table, val)
   for i=1,#table do
      if table[i] == val then
         return true
      end
   end
   return false
end

local triggerCharacters = vim.fn.split('0123456789.eE', '\\zs')
for op,_ in pairs(op) do
    for char in string.gmatch(op, '.') do
        if not contains(triggerCharacters, char) then
            triggerCharacters[#triggerCharacters+1] = char
        end
    end
end

-- Create the regex that determines if the text a valid RPN expression.
local operators = {}
for op,_ in pairs(op) do
    operators[#operators+1] = vim.fn.escape(op, [[~^*/\+%|<>&]] )
end

local numberRegex = [[[-+]?%(0|0?\.\d+|[1-9]\d*%(\.\d+)?)%([Ee][+-]?\d+)?]]  -- 0, -42, 3.14, 6.02e23, etc.
local numberRegex = numberRegex .. '%(,' .. numberRegex .. ')?'  -- now they can be complex (an ordered pair)
local operatorsRegex = table.concat(operators,[[|]])  -- Concatenate all operators:  sin|cos|+|-|pi|...
local wordRegex = [[%(]] .. numberRegex .. [[|]] .. operatorsRegex .. [[)]]  -- A word is a number or an operator.
local expressionRegex = wordRegex .. [[%( +]] .. wordRegex .. [[)*]]  -- Multiple space-delimited words.
expressionRegex = [[\v]] .. expressionRegex  -- Very magic

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
    local s,e = vim.regex(expressionRegex):match_str(input)
    if not s or not e then
        return callback({isIncomplete=true})
    end
    input = string.sub(input, s+1)

    stack = {}
    for _,word in ipairs(vim.fn.split(input, ' \\+')) do
        local number = tonumber(word)
        -- vim.pretty_print(word)
        if number then
            push(number)
        elseif word:match('.+,.+') then
            local c = vim.fn.split(word, ',')
            push({tonumber(c[1]), tonumber(c[2])})
        else
            local f = op[word]
            local ok,_ = pcall(f)
            if not ok then
                return callback({isIncomplete=true})
            end
        end
        -- vim.pretty_print(stack)
    end
    local value = ''
    for _,n in ipairs(stack) do
        if math.iscomplex(n) then
            value = value .. ' ' .. n[1] .. (n[2] >= 0 and '+' or '') .. n[2] .. 'i'
        else
            value = value .. ' ' .. n
        end
    end
    value = string.gsub(value, "^%s*(.-)%s*$", "%1")
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    callback({
        items = {{
            label = input .. ' ▶ ' .. value,
            textEdit = {
                range = {
                    start = { line = request.context.cursor.row-1, character = s, },
                    ['end'] = { line = request.context.cursor.row-1, character = request.context.cursor.col-1, }, },
                newText = value },
        }},
        isIncomplete = true,
    })
end

return source
