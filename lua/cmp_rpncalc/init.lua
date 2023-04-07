local bit=require('bit')
local stack = {}

local function pop()
    return table.remove(stack)
end

local function push(value)
    table.insert(stack, value)
end

-- Extend the math library with some basic functions I'll need below.
math.isreal = function(x) return type(x) == 'number' end
math.iscomplex = function(x) return type(x) == 'table' and #x == 2 and type(x[1]) == 'number' and type(x[2]) == 'number' end
math.round = function(x) return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5) end -- Round to nearest integer
math.trunc = function(x) return x>=0 and math.floor(x) or math.ceil(x) end -- Round toward zero

local op= {}

-- Basic Arithmetic --------------------------------------------------------------------------------
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
    if math.isreal(x)        then push('nan')
    elseif math.iscomplex(x) then push(math.atan2(x[2], x[1]));
    end
end
op[ [[chs]] ]   = function() -- Change Sign
    local x=pop()
    if math.isreal(x)        then push(-x)
    elseif math.iscomplex(x) then push({-x[1], -x[2]})
    end
end


-- Rounding --------------------------------------------------------------------------------
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


-- Powers & Logs --------------------------------------------------------------------------------
-- ln(a+bi)   =   ln(re^it)  =  ln(r)+ln(e^it)  =  ln(r)+it
op[ [[log]] ]   = function() -- Natural log of x
        local x=pop()
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
op[ [[**]] ] = function() -- Exponentiation - y to the x power
    local x,y = pop(), pop()
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
op[ [[exp]] ]   = function()
    local x=pop()
    push(math.exp(1))
    push(x)
    pcall(op[ [[**]] ])
end -- Raise e to the x power
op[ [[\]] ]     = function() push(-1); pcall(op[ [[**]] ]) end -- Reciprocal
op[ [[sqrt]] ]  = function() push(0.5); pcall(op[ [[**]] ]) end -- Square root of x


-- Trigonometry --------------------------------------------------------------------------------
op[ [[deg]] ]   = function() push(math.deg(pop())) end -- convert x to degrees
op[ [[rad]] ]   = function() push(math.rad(pop())) end -- convert x to radians
--
-- Using these identities, we can calculate trig values of complex numbers:
--    sin(z) = (e^iz - e^-iz) / 2i         cos(z) = (e^iz + e^-iz) / 2
--    sin(iz) = (e^iiz - e^-iiz) / 2i      cos(iz) = (e^iiz + e^-iiz) / 2
--            = i*(e^z - e^-z) / 2                 = (e^-z + e^z) / 2
--            = i*sinh(z)                          = cosh(z)
--
-- sin(a+bi) = sin(a)*cos(bi) + cos(a)*sin(bi)*i   =   sin(a)*cosh(b) + cos(a)*sinh(b)*i
-- cos(a+bi) = cos(z)*cos(bi) - sin(a)*sin(bi)*i   =   cos(a)*cosh(b) - sin(a)*sinh(b)*i
--
-- sinh(a+bi) = -i*sin(ia+ibi) = -i*sin(-b+ai) = -i*(sin(-b)*cosh(a) + cos(-b)*sinh(a)*i) =  cos(b)*sinh(a) + sin(b)*cosh(a)*i
-- cosh(a+bi) = cos(ia+ibi)    = cos(-b+ai)    = cos(-b)*cosh(a) - sin(-b)*sinh(a)*i =   cos(b)*cosh(a) + sin(b)*sinh(a)*i
--
-- Then, as usual, tan = sin / cos,      csc = 1 / sin,     sec = 1 / cos,     cot = 1 / tan
--                 tanh = sinh / cosh,   csch = 1 / sinh,   sech = 1 / cosh,   coth = 1 / tanh
--
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
        pcall(op[ [[log]] ])
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
        pcall(op[ [[log]] ])
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
op[ [[sinh]] ]  = function() -- Hyperbolic sine
    local x=pop()
    if math.iscomplex(x) then push({math.cos(x[2])*math.sinh(x[1]), math.sin(x[2])*math.cosh(x[1])})
    elseif math.isreal(x) then push(math.sinh(x))
    end
end
op[ [[cosh]] ]  = function() -- Hyperbolic cosine
    local x=pop()
    if math.iscomplex(x) then push({math.cos(x[2])*math.cosh(x[1]), math.sin(x[2])*math.sinh(x[1])})
    elseif math.isreal(x) then push(math.cosh(x))
    end
end
op[ [[tanh]] ]  = function() -- Hyperbolic tangent
    local x=pop()
    if math.iscomplex(x) then
        push(x)
        pcall(op[ [[sinh]] ])
        push(x)
        pcall(op[ [[cosh]] ])
        pcall(op[ [[/]] ])
    elseif math.isreal(x) then
        push(math.tanh(x))
    end
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
op[ [[asinh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x+1))) end -- Inverse hyperbolic sine
op[ [[acosh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x-1))) end -- Inverse hyperbolic cosine
op[ [[atanh]] ] = function() local x=pop(); push(math.log((1+x) / (1-x)) / 2) end -- Inverse hyperbolic tangent
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
op[ [[hms]] ]   = function()  -- Convert X hours to Z:Y:X
    local x=pop()
    for _=1,2 do
        local t=x<0 and math.ceil(x) or math.floor(x)
        push(t)
        x=60*(x-t)
    end
    push(x)
end

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
