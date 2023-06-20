local bit=require('bit')
local stack = {}
local base = 10
local memory = nil
local lastx = nil

local function pop()
    return table.remove(stack)
end

local function push(value)
    table.insert(stack, value)
end

-- Extend the math library with some basic functions I'll need below.
math.nan = 0/0
math.isNan = function(x) return tostring(x) == tostring(math.nan) end
math.isPosInf = function(x) return tostring(x) == tostring(0^-1) end
math.isNegInf = function(x) return tostring(x) == tostring(-0^-1) end
math.isreal = function(x) return type(x) == 'number' end
math.iscomplex = function(x) return type(x) == 'table' and #x == 2 and type(x[1]) == 'number' and type(x[2]) == 'number' end
math.round = function(x) return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5) end -- Round to nearest integer
math.trunc = function(x) return x>=0 and math.floor(x) or math.ceil(x) end -- Round toward zero

local op= {}

-- #############################################################################################
-- ############################################################################ Basic Arithmetic
-- #############################################################################################
op[ [[+]] ] = function()  -- Addtion
    local x,y = pop(), pop()
    if math.isreal(x)        and math.isreal(y)    then push(x + y)
    elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] + y, x[2]})
    elseif math.isreal(x)    and math.iscomplex(y) then push({x + y[1], y[2]})
    elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1] + y[1], x[2] + y[2]})
    end
end
op[ [[-]] ] = function() -- Subtraction
    local x,y = pop(), pop()
    if math.isreal(x)        and math.isreal(y)    then push(y - x)
    elseif math.iscomplex(x) and math.isreal(y)    then push({y - x[1], -x[2]})
    elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] - x, y[2]})
    elseif math.iscomplex(x) and math.iscomplex(y) then push({y[1] - x[1], y[2] - x[2]})
    end
end
op[ [[*]] ] = function() -- Multiplication
    local x,y = pop(), pop()
    if math.isreal(x)        and math.isreal(y)    then push(x * y)
    elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] * y, x[2] * y})
    elseif math.isreal(x)    and math.iscomplex(y) then push({x * y[1], x * y[2]})
    elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1]*y[1] - x[2]*y[2], x[1]*y[2] + x[2]*y[1]})
    end
end
op[ [[/]] ] = function() -- Division
    local x,y = pop(), pop()
    if     math.isreal(x)    and math.isreal(y)    then push(y / x)
    elseif math.iscomplex(x) and math.isreal(y)    then push({y*x[1]/(x[1]*x[1] + x[2]*x[2]), -y*x[2]/(x[1]*x[1] + x[2]*x[2])})
    elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] / x, y[2] / x})
    elseif math.iscomplex(x) and math.iscomplex(y) then push({(y[1]*x[1]+y[2]*x[2]) / (x[1]*x[1]+x[2]*x[2]), (y[2]*x[1]-y[1]*x[2]) / (x[1]*x[1]+x[2]*x[2])})
    end
end
op[ [[div]] ]   = function()  -- Integer part of division
    local x,y = pop(), pop()
    push(math.trunc(y / x))
end
op[ [[%]] ]     = function()  -- Modulus
    local x,y = pop(), pop()
    push(y % x)
end

op[ [[abs]] ]   = function() -- Absolute Value
    local x=pop()
    if math.isreal(x)        then push(math.abs(x))
    elseif math.iscomplex(x) then push(math.sqrt(x[1]*x[1] + x[2]*x[2]))
    end
end
op[ [[arg]] ]   = function() -- Arg
    local x=pop()
    if math.isreal(x)        then push(x < 0 and math.pi or 0)
    elseif math.iscomplex(x) then push(math.atan2(x[2], x[1]));
    end
end
op[ [[chs]] ]   = function() -- Change Sign
    local x=pop()
    if math.isreal(x)        then push(-x)
    elseif math.iscomplex(x) then push({-x[1], -x[2]})
    end
end


-- #############################################################################################
-- #################################################################################### Rounding
-- #############################################################################################
op[ [[floor]] ] = function() -- Floor - round down to nearest integer
    local x=pop()
    if math.isreal(x)        then push(math.floor(x))
    elseif math.iscomplex(x) then push({math.floor(x[1]), math.floor(x[2])})
    end
end
op[ [[ceil]] ]  = function() -- Ceiling - round up to nearest integer
    local x=pop()
    if math.isreal(x)        then push(math.ceil(x))
    elseif math.iscomplex(x) then push({math.ceil(x[1]), math.ceil(x[2])})
    end
end
op[ [[round]] ] = function() -- Round to nearest integer
    local x=pop()
    if math.isreal(x)        then push(math.round(x))
    elseif math.iscomplex(x) then push({math.round(x[1]), math.round(x[2])})
    end
end
op[ [[trunc]] ] = function() -- Round toward zero
    local x=pop()
    if math.isreal(x)        then push(math.trunc(x))
    elseif math.iscomplex(x) then push({math.trunc(x[1]), math.trunc(x[2])})
    end
end


-- #############################################################################################
-- ############################################################################### Powers & Logs
-- #############################################################################################
op[ [[ln]] ]   = function() -- Natural log of x
        local x=pop()
    if math.iscomplex(x) then
            local r = math.sqrt(x[1]*x[1] + x[2]*x[2])
            local theta = math.atan2(x[2],x[1])
            push({math.log(r), theta})
        elseif math.isreal(x) then
            push(math.log(x))
        end
    end
op[ [[log]] ] = function() pcall(op[ [[ln]] ]); push(10); pcall(op[ [[ln]] ]); pcall(op[ [[/]] ]) end -- Log (base 10) of x
op[ [[log2]] ] = function() pcall(op[ [[ln]] ]); push(2); pcall(op[ [[ln]] ]); pcall(op[ [[/]] ]) end -- Log (base 2) of x
op[ [[logx]] ]  = function() local x=pop(); pcall(op[ [[ln]] ]); push(x); pcall(op[ [[ln]] ]); pcall(op[ [[/]] ]) end -- Log y of x
op[ [[**]] ] = function() -- Exponentiation - y to the x power
    local x,y = pop(), pop()
    if ((math.iscomplex(y) and y[1]==0 and y[2]==0) or y == 0) and
        ((math.iscomplex(x) and x[1]==0 and x[2]==0) or x == 0) then push(math.nan)
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
op[ [[exp]] ]   = function()
    local x=pop()
    push(math.exp(1))
    push(x)
    pcall(op[ [[**]] ])
end -- Raise e to the x power
op[ [[\]] ]     = function() push(-1); pcall(op[ [[**]] ]) end -- Reciprocal
op[ [[sqrt]] ]  = function() push(0.5); pcall(op[ [[**]] ]) end -- Square root of x


-- #############################################################################################
-- ################################################################################ Trigonometry
-- #############################################################################################
op[ [[sin]] ]   = function() -- Sine
    local x=pop()
    if math.iscomplex(x) then
        push({math.sin(x[1])*math.cosh(x[2]), math.cos(x[1])*math.sinh(x[2])})
    elseif math.isreal(x) then push(math.sin(x))
    end
end
op[ [[cos]] ]   = function() -- Cosine
    local x=pop()
    if math.iscomplex(x) then push({math.cos(x[1])*math.cosh(x[2]), -math.sin(x[1])*math.sinh(x[2])})
    elseif math.isreal(x) then push(math.cos(x))
    end
end
op[ [[tan]] ]   = function() -- Tangent
    local x=pop()
    if math.iscomplex(x) then
        push(x)
        pcall(op[ [[sin]] ])
        push(x)
        pcall(op[ [[cos]] ])
        pcall(op[ [[/]] ])
    elseif math.isreal(x) then push(math.tan(x))
    end
end
op[ [[csc]] ]   = function() pcall(op[ [[sin]] ]); pcall(op[ [[\]] ]); end -- Cosecant
op[ [[sec]] ]   = function() pcall(op[ [[cos]] ]); pcall(op[ [[\]] ]); end -- Secant
op[ [[cot]] ]   = function() pcall(op[ [[tan]] ]); pcall(op[ [[\]] ]); end -- Cotangent
-- Inverse Trigonometry ------------------------------------------------------------------------
op[ [[asin]] ]  = function() -- Inverse sine
    local x=pop()
    if math.iscomplex(x) then -- i*ln(sqrt(1-x^2)-ix)
        push({0,1})
        push(1)
        push(x)
        push(2)
        pcall(op[ [[**]] ])
        pcall(op[ [[-]] ])
        pcall(op[ [[sqrt]] ])
        push({0,1})
        push(x)
        pcall(op[ [[*]] ])
        pcall(op[ [[-]] ])
        pcall(op[ [[ln]] ])
        pcall(op[ [[*]] ])
    else
        push(math.asin(x))
    end
end
op[ [[acos]] ]  = function() -- Inverse cosine = pi/2 - asin(x)
    local x=pop()
    pcall(op[ [[pi]] ])
    push(2)
    pcall(op[ [[/]] ])
    push(x)
    pcall(op[ [[asin]] ])
    pcall(op[ [[-]] ])
end
op[ [[atan]] ]  = function() -- Inverse Tangent
    local x=pop()
    if math.iscomplex(x) then -- -i/2*ln((1+ix)/(1-ix))
        push({0,-0.5})
        push(1)
        push({0,1})
        push(x)
        pcall(op[ [[*]] ])
        pcall(op[ [[+]] ])
        push(1)
        push({0,1})
        push(x)
        pcall(op[ [[*]] ])
        pcall(op[ [[-]] ])
        pcall(op[ [[/]] ])
        pcall(op[ [[ln]] ])
        pcall(op[ [[*]] ])
    else
        push(math.atan(x))
    end
end
op[ [[acsc]] ]  = function() -- Inverse cosecant
    pcall(op[ [[\]] ])
    pcall(op[ [[asin]] ])
end
op[ [[asec]] ]  = function() -- Inverse secant
    pcall(op[ [[\]] ])
    pcall(op[ [[acos]] ])
end
op[ [[acot]] ]  = function() -- Inverse cotangent
    pcall(op[ [[\]] ])
    pcall(op[ [[atan]] ])
end
-- Hyperbolic Trigonometry ---------------------------------------------------------------------
op[ [[sinh]] ]  = function() -- Hyperbolic sine
    local x=pop()
    if math.iscomplex(x) then
        push({math.cos(x[2])*math.sinh(x[1]), math.sin(x[2])*math.cosh(x[1])})
    elseif math.isreal(x) then
        push(math.sinh(x))
    end
end
op[ [[cosh]] ]  = function() -- Hyperbolic cosine
    local x=pop()
    if math.iscomplex(x) then
        push({math.cos(x[2])*math.cosh(x[1]), math.sin(x[2])*math.sinh(x[1])})
    elseif math.isreal(x) then
        push(math.cosh(x))
    end
end
op[ [[tanh]] ]  = function() -- Hyperbolic tangent
    local x=pop()
    push(x)
    pcall(op[ [[sinh]] ])
    push(x)
    pcall(op[ [[cosh]] ])
    pcall(op[ [[/]] ])
end
op[ [[csch]] ]  = function() -- Hyperbolic cosecant
    pcall(op[ [[sinh]] ])
    pcall(op[ [[\]] ])
end
op[ [[sech]] ]  = function() -- Hyperbolic secant
    pcall(op[ [[cosh]] ])
    pcall(op[ [[\]] ])
end
op[ [[coth]] ]  = function() -- Hyperbolic cotangent
    pcall(op[ [[tanh]] ])
    pcall(op[ [[\]] ])
end
-- Inverse Hyperbolic Trigonometry -------------------------------------------------------------
op[ [[asinh]] ] = function() -- Inverse hyperbolic sine
    local x=pop()
    push(x)
    push(x)
    push(x)
    pcall(op[ [[*]] ])
    push(1)
    pcall(op[ [[+]] ])
    pcall(op[ [[sqrt]] ])
    pcall(op[ [[+]] ])
    pcall(op[ [[ln]] ])
end
op[ [[acosh]] ] = function() -- Inverse hyperbolic cosine
    local x=pop()
    push(x)
    push(x)
    push(x)
    pcall(op[ [[*]] ])
    push(1)
    pcall(op[ [[-]] ])
    pcall(op[ [[sqrt]] ])
    pcall(op[ [[+]] ])
    pcall(op[ [[ln]] ])
end
op[ [[atanh]] ] = function() -- Inverse hyperbolic tangent
    local x=pop()
    push(1)
    push(x)
    pcall(op[ [[+]] ])
    push(1)
    push(x)
    pcall(op[ [[-]] ])
    pcall(op[ [[/]] ])
    pcall(op[ [[ln]] ])
    push(2)
    pcall(op[ [[/]] ])
end
op[ [[acsch]] ] = function() -- Inverse hyperbolic cosecant
    local x=pop()
    push(1)
    push(x)
    push(x)
    pcall(op[ [[*]] ])
    pcall(op[ [[+]] ])
    pcall(op[ [[sqrt]] ])
    push(1)
    pcall(op[ [[+]] ])
    push(x)
    pcall(op[ [[/]] ])
    pcall(op[ [[ln]] ])
end
op[ [[asech]] ] = function() -- Inverse hyperbolic secant
    local x=pop()
    push(1)
    push(x)
    push(x)
    pcall(op[ [[*]] ])
    pcall(op[ [[-]] ])
    pcall(op[ [[sqrt]] ])
    push(1)
    pcall(op[ [[+]] ])
    push(x)
    pcall(op[ [[/]] ])
    pcall(op[ [[ln]] ])
end
op[ [[acoth]] ] = function() -- Inverse hyperbolic cotangent
    local x=pop()
    push(x)
    push(1)
    pcall(op[ [[+]] ])
    push(x)
    push(1)
    pcall(op[ [[-]] ])
    pcall(op[ [[/]] ])
    pcall(op[ [[ln]] ])
    push(2)
    pcall(op[ [[/]] ])
end
-- Angle Conversion ----------------------------------------------------------------------------
op[ [[deg]] ]   = function() push(math.deg(pop())) end -- convert x to degrees
op[ [[rad]] ]   = function() push(math.rad(pop())) end -- convert x to radians


-- #############################################################################################
-- ##################################################################################### Bitwise
-- #############################################################################################
op[ [[&]] ]     = function() push(bit.band(pop(),pop())) end -- AND
op[ [[|]] ]     = function() push(bit.bor(pop(),pop())) end -- OR
op[ [[^]] ]     = function() push(bit.bxor(pop(),pop())) end -- XOR
op[ [[~]] ]     = function() push(bit.bnot(pop())) end -- NOT
op[ [[<<]] ]    = function() local n=pop(); push(bit.lshift(pop(),n)) end -- Left Shift
op[ [[>>]] ]    = function() local n=pop(); push(bit.rshift(pop(),n)) end -- Right Shift


-- #############################################################################################
-- ################################################################################### Constants
-- #############################################################################################
op[ [[pi]] ]  = function() push(math.pi);            lastx = stack[#stack] end -- 3.141592653...
op[ [[e]] ]   = function() push(math.exp(1));        lastx = stack[#stack] end -- 2.718281828...
op[ [[phi]] ] = function() push((1+math.sqrt(5))/2); lastx = stack[#stack] end -- 1.618033989
op[ [[i]] ]   = function() push({0,1});              lastx = stack[#stack] end -- the imaginary unit value


-- #############################################################################################
-- ####################################################################################### Other
-- #############################################################################################
op[ [[hrs]] ]   = function() push((pop() / 60 + pop()) / 60 + pop()) end -- Convert Z:Y:X to hours
op[ [[hms]] ]   = function()  -- Convert X hours to Z:Y:X
    local x=pop()
    for _=1,2 do
        local t=x<0 and math.ceil(x) or math.floor(x)
        push(t)
        x=60*(x-t)
    end
    push(x)
end

-- #############################################################################################
-- ################################################################### Bases (Reading & Writing)
-- #############################################################################################
op[ [[bin]] ] = function() base = 2 end  -- Change output to binary
op[ [[hex]] ] = function() base = 16 end -- Change output to hexadecimal
op[ [[dec]] ] = function() base = 10 end -- Change output to decimal

-- #############################################################################################
-- ################################################################# Memory & Stack Manipulation
-- #############################################################################################
op[ [[xm]] ]   = function() local x = pop(); memory = x; push(x); end -- store X in memory
op[ [[rm]] ]   = function() push(memory); end -- recall memory to the stack
op[ [[m+]] ]   = function() local x = pop(); memory = memory + x; push(x); end -- add X to memory
op[ [[m-]] ]   = function() local x = pop(); memory = memory - x; push(x); end -- subtract X from memory
op[ [[xy]] ]   = function() local x,y = pop(), pop(); push(x); push(y); end -- swap X and Y
op[ [[x]] ]    = function() push(lastx); end -- swap X and Y
op[ [[drop]] ] = function() pop(); end; -- drop X off the stack

-- #############################################################################################
-- ################################################################################## Statistics
-- #############################################################################################
op[ [[!]] ] = function()  -- Factorial
    local x = pop();
    if math.iscomplex(x) or math.floor(x) ~= x or x < 0 then
        push(math.nan)
        return
    end

    local f = 1
    for i=1,x do
        f = f * i
    end
    push(f)
end
op[ [[perm]] ] = function()  -- Permutations of Y things taken X at a time
    local x,y = pop(),pop()
    push(y)
    pcall(op[ [[!]] ])
    push(y)
    push(x)
    pcall(op[ [[-]] ])
    pcall(op[ [[!]] ])
    pcall(op[ [[/]] ])
end
op[ [[comb]] ] = function()  -- Combinations of Y things taken X at a time
    local x,y = pop(),pop()
    push(y)
    pcall(op[ [[!]] ])
    push(y)
    push(x)
    pcall(op[ [[-]] ])
    pcall(op[ [[!]] ])
    push(x)
    pcall(op[ [[!]] ])
    pcall(op[ [[*]] ])
    pcall(op[ [[/]] ])
end
op[ [[n]] ] = function()  -- Count of all numbers on stack
    stack = {#stack}
end
op[ [[sum]] ] = function()  -- Sum of all numbers on stack
    local n = #stack
    for _ = 1,n-1 do
        pcall(op[ [[+]] ])
    end
end
op[ [[ssq]] ] = function()  -- Sum of squares of all numbers on stack
    local n = #stack
    push(2)
    pcall(op[ [[**]] ])
    for _ = 1,n-1 do
        pcall(op[ [[xy]] ])
        push(2)
        pcall(op[ [[**]] ])
        pcall(op[ [[+]] ])
    end
end
op[ [[mean]] ] = function()  -- Mean average of all numbers on stack
    local n = #stack
    pcall(op[ [[sum]] ])
    push(n)
    pcall(op[ [[/]] ])
end
op[ [[std]] ] = function()  -- Standard deviation of all numbers on stack
    local s = {unpack(stack)}
    local n = #stack

    pcall(op[ [[mean]] ])
    local mean = stack[#stack]
    if math.iscomplex(mean) then
        stack = {math.nan}
    else
        local sum = 0
        for i = 1,n do
            sum = sum + (s[i] - mean) ^ 2
        end
        stack = {math.sqrt(sum / (n-1))}
    end
end


-- #############################################################################################
-- ############################################################### End of Operators' Definitions
-- #############################################################################################

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

local triggerCharacters = vim.fn.split('bx0123456789.eE', '\\zs')
for o,_ in pairs(op) do
    for char in string.gmatch(o, '.') do
        if not contains(triggerCharacters, char) then
            triggerCharacters[#triggerCharacters+1] = char
        end
    end
end

-- Create the regex that determines if the text is a valid RPN expression.
local operators = {}
for o,_ in pairs(op) do
    operators[#operators+1] = vim.fn.escape(o, [[~^*/\+%|<>&]] )
end

local numberRegex = [[-?%(0|0?\.\d+|[1-9]\d*%(\.\d+)?)%([Ee][+-]?\d+)?]]  -- 0, .5, -42, 3.14, 6.02e23, etc.
numberRegex = [[%(]] .. numberRegex .. [[|-?0b[01]+|-?0x[0-9a-fA-F]+]] .. [[)]] -- Include binary and hexadecimal.
numberRegex = numberRegex .. '%(,' .. numberRegex .. ')?'  -- Complex number, an ordered pair.
local operatorsRegex = table.concat(operators,[[|]])  -- Concatenate all operators:  sin|cos|+|-|pi|...
local wordRegex = [[%(]] .. numberRegex .. [[|]] .. operatorsRegex .. [[)]]  -- A word is a number or an operator.
local expressionRegex = wordRegex .. [[%( +]] .. wordRegex .. [[)*]]  -- Multiple space-delimited words.
expressionRegex = [[\v]] .. expressionRegex  -- Very magic

local function changeBase(num)
    if type(num) == 'string' then return num end

    local sign = num < 0 and '-' or ''
    if base == 10 then return string.format('%s', num) end
    if base == 16 then return string.format('%s0x%x', sign, math.abs(num)) end
    if base == 2 then
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
local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
    return triggerCharacters
end

source.complete = function(_, request, callback)
    base = 10
    memory = nil
    lastx = nil
    local input = request.context.cursor_before_line
    local s,e = vim.regex(expressionRegex):match_str(input)
    -- vim.pretty_print(s,e,input)
    if not s or not e then
        return callback({})
    end
    input = string.sub(input, s+1)

    stack = {}
    for _,word in ipairs(vim.fn.split(input, ' \\+')) do
        local number = tonumber(word)
        -- vim.pretty_print(word)
        if number then
            push(number)
            lastx = stack[#stack]
        elseif word:match('.+,.+') then
            local c = vim.fn.split(word, ',')
            push({tonumber(c[1]), tonumber(c[2])})
            lastx = stack[#stack]
        else
            local f = op[word]
            local ok,_ = pcall(f)
            if not ok then
                return callback({})
            end
        end
        -- vim.pretty_print(stack)
    end

    local value = ''
    for _,n in ipairs(stack) do
        if math.isNan(n) then
            value = value .. ' NaN'
        elseif math.isPosInf(n) then
            value = value .. ' Infinity'
        elseif math.isNegInf(n) then
            value = value .. ' -Infinity'
        elseif math.iscomplex(n) then
            if math.isNan(n[1]) or math.isNan(n[2]) then
                value = value .. ' NaN'
            elseif math.isPosInf(n[1]) or math.isPosInf(n[2]) then
                value = value .. ' Infinity'
            elseif math.isNegInf(n[1]) or math.isNegInf(n[2]) then
                value = value .. ' -Infinity'
            else
                value = value .. ' ' .. changeBase(n[1]) .. (n[2] >= 0 and '+' or '') .. changeBase(n[2]) .. 'i'
            end
        elseif math.isreal(n) then
            value = value .. ' ' .. changeBase(n)
        else
            value = value .. ' ' .. 'Error'
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
