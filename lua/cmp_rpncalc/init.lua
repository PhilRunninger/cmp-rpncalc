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

local operatorFunc= {}

operatorFunc[ [[+]] ] = function()
        local x=pop(); local y=pop();  -- Addtion
        if math.isreal(x)        and math.isreal(y)    then push(x + y)
        elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] + y, x[2]})
        elseif math.isreal(x)    and math.iscomplex(y) then push({x + y[1], y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1] + y[1], x[2] + y[2]})
        end
    end
operatorFunc[ [[-]] ] = function() local x=pop(); local y=pop();  -- Subtraction
        if math.isreal(x)        and math.isreal(y)    then push(y - x)
        elseif math.iscomplex(x) and math.isreal(y)    then push({y - x[1], -x[2]})
        elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] - x, y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({y[1] - x[1], y[2] - x[2]})
        end
    end
operatorFunc[ [[*]] ] = function() local x=pop(); local y=pop();  -- Multiplication
        if math.isreal(x)        and math.isreal(y)    then push(x * y)
        elseif math.iscomplex(x) and math.isreal(y)    then push({x[1] * y, x[2] * y})
        elseif math.isreal(x)    and math.iscomplex(y) then push({x * y[1], x * y[2]})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({x[1]*y[1] - x[2]*y[2], x[1]*y[2] + x[2]*y[1]})
        end
    end
operatorFunc[ [[/]] ] = function() local x=pop(); local y=pop();  -- Division
        if     math.isreal(x)    and math.isreal(y)    then push(y / x)
        elseif math.iscomplex(x) and math.isreal(y)    then push({y*x[1]/(x[1]*x[1] + x[2]*x[2]), -y*x[2]/(x[1]*x[1] + x[2]*x[2])})
        elseif math.isreal(x)    and math.iscomplex(y) then push({y[1] / x, y[2] / x})
        elseif math.iscomplex(x) and math.iscomplex(y) then push({(y[1]*x[1]+y[2]*x[2]) / (x[1]*x[1]+x[2]*x[2]), (y[2]*x[1]-y[1]*x[2]) / (x[1]*x[1]+x[2]*x[2])})
        end
    end
operatorFunc[ [[div]] ]   = function() local r=1 / pop() * pop(); push(math.trunc(r)) end -- Integer part of division
operatorFunc[ [[%]] ]     = function() local x=pop(); local y=pop(); push(y % x) end  -- Modulus

operatorFunc[ [[abs]] ]   = function() local x=pop();  -- Absolute Value
        if math.isreal(x)        then push(math.abs(x))
        elseif math.iscomplex(x) then push(math.sqrt(x[1]*x[1] + x[2]*x[2]))
        end
    end
operatorFunc[ [[arg]] ]   = function() local x=pop();  -- Arg
        if math.isreal(x)        then push('nan')
        elseif math.iscomplex(x) then push(math.atan2(x[2], x[1]));
        end
    end

operatorFunc[ [[chs]] ]   = function() local x=pop();  -- Change Sign
        if math.isreal(x)        then push(-x)
        elseif math.iscomplex(x) then push({-x[1], -x[2]})
        end
    end

-- Rounding
operatorFunc[ [[floor]] ] = function() local x = pop();  -- Floor - round down to nearest integer
        if math.isreal(x)        then push(math.floor(x))
        elseif math.iscomplex(x) then push({math.floor(x[1]), math.floor(x[2])})
        end
    end
operatorFunc[ [[ceil]] ]  = function() local x = pop();  -- Ceiling - round up to nearest integer
        if math.isreal(x)        then push(math.ceil(x))
        elseif math.iscomplex(x) then push({math.ceil(x[1]), math.ceil(x[2])})
        end
    end
operatorFunc[ [[round]] ] = function() local x = pop();  -- Round to nearest integer
        if math.isreal(x)        then push(math.round(x))
        elseif math.iscomplex(x) then push({math.round(x[1]), math.round(x[2])})
        end
    end
operatorFunc[ [[trunc]] ] = function() local x = pop();  -- Round toward zero
        if math.isreal(x)        then push(math.trunc(x))
        elseif math.iscomplex(x) then push({math.trunc(x[1]), math.trunc(x[2])})
        end
    end
-- Powers & Logs
operatorFunc[ [[exp]] ]   = function() push(math.exp(pop())) end -- Raise e to the x power
operatorFunc[ [[log]] ]   = function() push(math.log(pop())) end -- Natural log of x
operatorFunc[ [[logx]] ]  = function() local x=pop(); push(math.log(pop(),x)) end -- Log y of x
operatorFunc[ [[log10]] ] = function() push(math.log(pop(),10)) end -- Log (base 10) of x
operatorFunc[ [[log2]] ]  = function() push(math.log(pop(),2) )end -- Log (base 2) of x
operatorFunc[ [[sqrt]] ]  = function() local x = pop(); -- Square Root
        if math.isreal(x)        then push(x<0 and {0,math.sqrt(-x)} or math.sqrt(x))
        elseif math.iscomplex(x) then push({0,0})
        end
    end
operatorFunc[ [[**]] ] = function() local x=pop(); local y=pop(); -- Exponentiation
        if math.iscomplex(x) and math.iscomplex(y) then
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
        else
            push((y==0 and x==0) and 'nan' or y ^ x)
        end
    end


           -- ("**",    [{C,D},{_,_}=Y|S]) -> [R] = rpn("abs",[Y]),
           --                                 [Theta] = rpn("arg",[Y]),
           --                                 Multiplier = math:exp(C*math:log(R) - D*Theta),
           --                                 [{Multiplier*math:cos(D*math:log(R) + C*Theta), Multiplier*math:sin(D*math:log(R) + C*Theta)}|S];
           -- ("**",    [X,{_,_}=Y    |S]) -> [R] = rpn("abs",[Y]),
           --                                 [Theta] = rpn("arg",[Y]),
           --                                 [{math:pow(R,X)*math:cos(Theta*X), math:pow(R,X)*math:sin(Theta*X)}|S];
           -- ("**",    [{A,B},Y      |S]) -> [{math:pow(Y,A)*math:cos(B*math:log(Y)), math:pow(Y,A)*math:sin(B*math:log(Y))}|S];
           -- ("**",    [X,Y          |S]) -> [math:pow(Y,X)|S];

operatorFunc[ [[\]] ]     = function() push(1 / pop()) end -- Reciprocal
-- Trigonometry
operatorFunc[ [[deg]] ]   = function() push(math.deg(pop())) end -- convert x to degrees
operatorFunc[ [[rad]] ]   = function() push(math.rad(pop())) end -- convert x to radians

operatorFunc[ [[sin]] ]   = function() push(math.sin(pop())) end -- Sine
operatorFunc[ [[cos]] ]   = function() push(math.cos(pop())) end -- Cosine
operatorFunc[ [[tan]] ]   = function() push(math.tan(pop())) end -- Tangent
operatorFunc[ [[csc]] ]   = function() push(1 / math.sin(pop())) end -- Cosecant
operatorFunc[ [[sec]] ]   = function() push(1 / math.cos(pop())) end -- Secant
operatorFunc[ [[cot]] ]   = function() push(1 / math.tan(pop())) end -- Cotangent

operatorFunc[ [[asin]] ]  = function() push(math.asin(pop())) end -- Inverse sine
operatorFunc[ [[acos]] ]  = function() push(math.acos(pop())) end -- Inverse cosine
operatorFunc[ [[atan]] ]  = function() push(math.atan(pop())) end -- Inverse Tangent
operatorFunc[ [[acsc]] ]  = function() push(math.asin(1 / pop())) end -- Inverse cosecant
operatorFunc[ [[asec]] ]  = function() push(math.acos(1 / pop())) end -- Inverse secant
operatorFunc[ [[acot]] ]  = function() push(math.atan(1 / pop())) end -- Inverse cotangent

operatorFunc[ [[sinh]] ]  = function() local x=pop(); push((math.exp(x) - math.exp(-x)) / 2) end -- Hyperbolic sine
operatorFunc[ [[cosh]] ]  = function() local x=pop(); push((math.exp(x) + math.exp(-x)) / 2) end -- Hyperbolic cosine
operatorFunc[ [[tanh]] ]  = function() local x=pop(); push((math.exp(2*x)-1) / (math.exp(2*x)+1)) end -- Hyperbolic tangent
operatorFunc[ [[asinh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x+1))) end -- Inverse hyperbolic sine
operatorFunc[ [[acosh]] ] = function() local x=pop(); push(math.log(x + math.sqrt(x*x-1))) end -- Inverse hyperbolic cosine
operatorFunc[ [[atanh]] ] = function() local x=pop(); push(math.log((1+x) / (1-x)) / 2) end -- Inverse hyperbolic tangent

operatorFunc[ [[csch]] ]  = function() local x=pop(); push(2 / (math.exp(x) - math.exp(-x))) end -- Hyperbolic cosecant
operatorFunc[ [[sech]] ]  = function() local x=pop(); push(2 / (math.exp(x) + math.exp(-x))) end -- Hyperbolic secant
operatorFunc[ [[coth]] ]  = function() local x=pop(); push((math.exp(2*x)+1) / (math.exp(2*x)-1)) end -- Hyperbolic cotangent
operatorFunc[ [[acsch]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1+x*x)) / x)) end -- Inverse hyperbolic cosecant
operatorFunc[ [[asech]] ] = function() local x=pop(); push(math.log((1+math.sqrt(1-x*x)) / x)) end -- Inverse hyperbolic secant
operatorFunc[ [[acoth]] ] = function() local x=pop(); push(math.log((x+1) / (x-1)) / 2) end -- Inverse hyperbolic cotangent

-- Bitwise
operatorFunc[ [[&]] ]     = function() push(bit.band(pop(),pop())) end -- AND
operatorFunc[ [[|]] ]     = function() push(bit.bor(pop(),pop())) end -- OR
operatorFunc[ [[^]] ]     = function() push(bit.bxor(pop(),pop())) end -- XOR
operatorFunc[ [[~]] ]     = function() push(bit.bnot(pop())) end -- NOT
operatorFunc[ [[<<]] ]    = function() local n=pop(); push(bit.lshift(pop(),n)) end -- Left Shift
operatorFunc[ [[>>]] ]    = function() local n=pop(); push(bit.rshift(pop(),n)) end -- Right Shift
-- Constants
operatorFunc[ [[pi]] ]    = function() push(math.pi) end -- 3.141592653....
operatorFunc[ [[e]] ]     = function() push(math.exp(1)) end -- 2.718281828...
operatorFunc[ [[phi]] ]   = function() push((1+math.sqrt(5)) / 2) end -- 1.618033989...
operatorFunc[ [[i]] ]     = function() push({0,1}) end -- the imaginary unit value
-- Other
operatorFunc[ [[hrs]] ]   = function() push((pop() / 60 + pop()) / 60 + pop()) end -- Convert Z:Y:X to hours
operatorFunc[ [[hms]] ]   = function() local x=pop(); for _=1,2 do local t=x<0 and math.ceil(x) or math.floor(x); push(t); x=60*(x-t); end; push(x) end -- Convert X hours to Z:Y:X

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

local triggerCharacters = vim.fn.split('0123456789.eE', '\\zs')
for op,_ in pairs(operatorFunc) do
    for char in string.gmatch(op, '.') do
        if not contains(triggerCharacters, char) then
            triggerCharacters[#triggerCharacters+1] = char
        end
    end
end

-- Create the regex that determines if the text a valid RPN expression.
local operators = {}
for op,_ in pairs(operatorFunc) do
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
            local f = operatorFunc[word]
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
            value = value .. ' ' .. n[1] .. (n[2] > 0 and '+' or '') .. n[2] .. 'i'
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
