local bit=require('bit')

-- Extend the math library with some basic functions I'll need below.
math.nan = 0/0
math.isNan = function(x) return tostring(x) == tostring(math.nan) end
math.isPosInf = function(x) return tostring(x) == tostring(0^-1) end
math.isNegInf = function(x) return tostring(x) == tostring(-0^-1) end
math.isInt = function(x) return math.isReal(x) and math.floor(x) == x end
math.isReal = function(x) return type(x) == 'number' end
math.isComplex = function(x) return type(x) == 'table' and #x == 2 and type(x[1]) == 'number' and type(x[2]) == 'number' end
math.round = function(x) return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5) end -- Round to nearest integer
math.trunc = function(x) return x>=0 and math.floor(x) or math.ceil(x) end -- Round toward zero

local M = {}

M.init = function()
    M.base = 10
    M.memory = nil
    M.lastx = nil
    M.stack = {}
end

M.pop = function()
    return table.remove(M.stack)
end

M.push = function(value)
    table.insert(M.stack, value)
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

M.triggerCharacters = function()
    local chars = vim.fn.split('bx0123456789.eE', '\\zs')
    for o,_ in pairs(M.op) do
        for char in string.gmatch(o, '.') do
            if not contains(chars, char) then
                chars[#chars+1] = char
            end
        end
    end
    return chars
end

-- Build the regex that tests the input for a valid RPN expression.
M.expressionRegex = function()
    local numRegex = [[-?%(0|0?\.\d+|[1-9]\d*%(\.\d+)?)%([Ee][+-]?\d+)?]]       -- 0, .5, -42, 3.14, 6.02e23, etc.
    numRegex = [[%(]] .. numRegex .. [[|-?0b[01]+|-?0x[0-9a-fA-F]+]] .. [[)]]   -- Include binary and hexadecimal.
    numRegex = numRegex .. '%(,' .. numRegex .. ')?'                            -- Complex numbers are entered as ordered pairs.

    local operRegex = ''
    for o,_ in pairs(M.op) do
        o = vim.fn.escape(o, [[~^*/\+%|<>&]] )                                  -- Escape special characters.
        o = (o:match('%a.*') and '<' or '') .. o                                -- Add beginning-of-word marker to alphabetic operators.
        operRegex = operRegex .. (operRegex == '' and '' or [[|]]) .. o         -- Concatenate all operators:  <sin|<cos|+|-|<pi|...
    end

    local wordRegex = [[%(]] .. numRegex .. [[|]] .. operRegex .. [[)]]         -- A word is a number or an operator.

    local expr = wordRegex .. [[%( +]] .. wordRegex .. [[)*]]                   -- An expression is multiple space-delimited words.
    expr = expr .. [[$]]                                                        -- Matching ends at the end of input string.
    expr = [[\v]] .. expr                                                       -- Very magic enables simplified regex syntax.
    -- vim.print(expr)
    return expr
end
local pop,push = M.pop,M.push

M.op= {
    -- #############################################################################################
    -- ############################################################################ Basic Arithmetic
    -- #############################################################################################
    [ [[+]] ] = function()  -- Addtion
        local x,y = pop(), pop()
        if math.isReal(x)        and math.isReal(y)    then push(x + y)
        elseif math.isComplex(x) and math.isReal(y)    then push({x[1] + y, x[2]})
        elseif math.isReal(x)    and math.isComplex(y) then push({x + y[1], y[2]})
        elseif math.isComplex(x) and math.isComplex(y) then push({x[1] + y[1], x[2] + y[2]})
        end
    end,
    [ [[-]] ] = function() -- Subtraction
        local x,y = pop(), pop()
        if math.isReal(x)        and math.isReal(y)    then push(y - x)
        elseif math.isComplex(x) and math.isReal(y)    then push({y - x[1], -x[2]})
        elseif math.isReal(x)    and math.isComplex(y) then push({y[1] - x, y[2]})
        elseif math.isComplex(x) and math.isComplex(y) then push({y[1] - x[1], y[2] - x[2]})
        end
    end,
    [ [[*]] ] = function() -- Multiplication
        local x,y = pop(), pop()
        if math.isReal(x)        and math.isReal(y)    then push(x * y)
        elseif math.isComplex(x) and math.isReal(y)    then push({x[1] * y, x[2] * y})
        elseif math.isReal(x)    and math.isComplex(y) then push({x * y[1], x * y[2]})
        elseif math.isComplex(x) and math.isComplex(y) then push({x[1]*y[1] - x[2]*y[2], x[1]*y[2] + x[2]*y[1]})
        end
    end,
    [ [[/]] ] = function() -- Division
        local x,y = pop(), pop()
        if     math.isReal(x)    and math.isReal(y)    then push(y / x)
        elseif math.isComplex(x) and math.isReal(y)    then push({y*x[1]/(x[1]*x[1] + x[2]*x[2]), -y*x[2]/(x[1]*x[1] + x[2]*x[2])})
        elseif math.isReal(x)    and math.isComplex(y) then push({y[1] / x, y[2] / x})
        elseif math.isComplex(x) and math.isComplex(y) then push({(y[1]*x[1]+y[2]*x[2]) / (x[1]*x[1]+x[2]*x[2]), (y[2]*x[1]-y[1]*x[2]) / (x[1]*x[1]+x[2]*x[2])})
        end
    end,
    [ [[div]] ]   = function()  -- Integer part of division
        local x,y = pop(), pop()
        push(math.trunc(y / x))
    end,
    [ [[%]] ]     = function()  -- Modulus
        local x,y = pop(), pop()
        push(y % x)
    end,

    [ [[abs]] ]   = function() -- Absolute Value
        local x=pop()
        if math.isReal(x)        then push(math.abs(x))
        elseif math.isComplex(x) then push(math.sqrt(x[1]*x[1] + x[2]*x[2]))
        end
    end,
    [ [[arg]] ]   = function() -- Arg
        local x=pop()
        if math.isReal(x)        then push(x < 0 and math.pi or 0)
        elseif math.isComplex(x) then push(math.atan2(x[2], x[1]));
        end
    end,
    [ [[chs]] ]   = function() -- Change Sign
        local x=pop()
        if math.isReal(x)        then push(-x)
        elseif math.isComplex(x) then push({-x[1], -x[2]})
        end
    end,


    -- #############################################################################################
    -- #################################################################################### Rounding
    -- #############################################################################################
    [ [[floor]] ] = function() -- Floor - round down to nearest integer
        local x=pop()
        if math.isReal(x)        then push(math.floor(x))
        elseif math.isComplex(x) then push({math.floor(x[1]), math.floor(x[2])})
        end
    end,
    [ [[ceil]] ]  = function() -- Ceiling - round up to nearest integer
        local x=pop()
        if math.isReal(x)        then push(math.ceil(x))
        elseif math.isComplex(x) then push({math.ceil(x[1]), math.ceil(x[2])})
        end
    end,
    [ [[round]] ] = function() -- Round to nearest integer
        local x=pop()
        if math.isReal(x)        then push(math.round(x))
        elseif math.isComplex(x) then push({math.round(x[1]), math.round(x[2])})
        end
    end,
    [ [[trunc]] ] = function() -- Round toward zero
        local x=pop()
        if math.isReal(x)        then push(math.trunc(x))
        elseif math.isComplex(x) then push({math.trunc(x[1]), math.trunc(x[2])})
        end
    end,


    -- #############################################################################################
    -- ############################################################################### Powers & Logs
    -- #############################################################################################
    [ [[ln]] ]   = function() -- Natural log of x
        local x=pop()
        if math.isComplex(x) then
            local r = math.sqrt(x[1]*x[1] + x[2]*x[2])
            local theta = math.atan2(x[2],x[1])
            push({math.log(r), theta})
        elseif math.isReal(x) then
            push(math.log(x))
        end
    end,
    [ [[log]] ] = function() pcall(M.op[ [[ln]] ]); push(10); pcall(M.op[ [[ln]] ]); pcall(M.op[ [[/]] ]) end, -- Log (base 10) of x
    [ [[log2]] ] = function() pcall(M.op[ [[ln]] ]); push(2); pcall(M.op[ [[ln]] ]); pcall(M.op[ [[/]] ]) end, -- Log (base 2) of x
    [ [[logx]] ]  = function() local x=pop(); pcall(M.op[ [[ln]] ]); push(x); pcall(M.op[ [[ln]] ]); pcall(M.op[ [[/]] ]) end, -- Log y of x
    [ [[**]] ] = function() -- Exponentiation - y to the x power
        local x,y = pop(), pop()
        if ((math.isComplex(y) and y[1]==0 and y[2]==0) or y == 0) and
            ((math.isComplex(x) and x[1]==0 and x[2]==0) or x == 0) then push(math.nan)
        elseif math.isComplex(x) and math.isComplex(y) then
            local r = math.sqrt(y[1]*y[1] + y[2]*y[2])
            local theta = math.atan2(y[2],y[1])
            local m = math.exp(x[1]*math.log(r) - x[2]*theta)
            push({m*math.cos(x[2]*math.log(r) + x[1]*theta), m*math.sin(x[2]*math.log(r) + x[1]*theta)})
        elseif math.isReal(x) and math.isComplex(y) then
            local r = math.sqrt(y[1]*y[1]+y[2]*y[2])
            local theta = math.atan2(y[2],y[1])
            push({math.pow(r,x)*math.cos(theta*x), math.pow(r,x)*math.sin(theta*x)})
        elseif math.isComplex(x) then
            push({math.pow(y,x[1])*math.cos(x[2]*math.log(y)), math.pow(y,x[1])*math.sin(x[2]*math.log(y))})
        elseif y < 0 and x ~= math.round(x) then
            push({y,0})
            push(x)
            pcall(M.op[ [[**]] ])
        else
            push(y ^ x)
        end
    end,
    [ [[exp]] ]   = function()
        local x=pop()
        push(math.exp(1))
        push(x)
        pcall(M.op[ [[**]] ])
    end, -- Raise e to the x power
    [ [[\]] ]     = function() push(-1); pcall(M.op[ [[**]] ]) end, -- Reciprocal
    [ [[sqrt]] ]  = function() push(0.5); pcall(M.op[ [[**]] ]) end, -- Square root of x


    -- #############################################################################################
    -- ################################################################################ Trigonometry
    -- #############################################################################################
    [ [[sin]] ]   = function() -- Sine
        local x=pop()
        if math.isComplex(x) then
            push({math.sin(x[1])*math.cosh(x[2]), math.cos(x[1])*math.sinh(x[2])})
        elseif math.isReal(x) then push(math.sin(x))
        end
    end,
    [ [[cos]] ]   = function() -- Cosine
        local x=pop()
        if math.isComplex(x) then push({math.cos(x[1])*math.cosh(x[2]), -math.sin(x[1])*math.sinh(x[2])})
        elseif math.isReal(x) then push(math.cos(x))
        end
    end,
    [ [[tan]] ]   = function() -- Tangent
        local x=pop()
        if math.isComplex(x) then
            push(x)
            pcall(M.op[ [[sin]] ])
            push(x)
            pcall(M.op[ [[cos]] ])
            pcall(M.op[ [[/]] ])
        elseif math.isReal(x) then push(math.tan(x))
        end
    end,
    [ [[csc]] ]   = function() pcall(M.op[ [[sin]] ]); pcall(M.op[ [[\]] ]); end, -- Cosecant
    [ [[sec]] ]   = function() pcall(M.op[ [[cos]] ]); pcall(M.op[ [[\]] ]); end, -- Secant
    [ [[cot]] ]   = function() pcall(M.op[ [[tan]] ]); pcall(M.op[ [[\]] ]); end, -- Cotangent
    -- Inverse Trigonometry ------------------------------------------------------------------------
    [ [[asin]] ]  = function() -- Inverse sine
        local x=pop()
        if math.isComplex(x) then -- i*ln(sqrt(1-x^2)-ix)
            push({0,1})
            push(1)
            push(x)
            push(2)
            pcall(M.op[ [[**]] ])
            pcall(M.op[ [[-]] ])
            pcall(M.op[ [[sqrt]] ])
            push({0,1})
            push(x)
            pcall(M.op[ [[*]] ])
            pcall(M.op[ [[-]] ])
            pcall(M.op[ [[ln]] ])
            pcall(M.op[ [[*]] ])
        else
            push(math.asin(x))
        end
    end,
    [ [[acos]] ]  = function() -- Inverse cosine = pi/2 - asin(x)
        local x=pop()
        pcall(M.op[ [[pi]] ])
        push(2)
        pcall(M.op[ [[/]] ])
        push(x)
        pcall(M.op[ [[asin]] ])
        pcall(M.op[ [[-]] ])
    end,
    [ [[atan]] ]  = function() -- Inverse Tangent
        local x=pop()
        if math.isComplex(x) then -- -i/2*ln((1+ix)/(1-ix))
            push({0,-0.5})
            push(1)
            push({0,1})
            push(x)
            pcall(M.op[ [[*]] ])
            pcall(M.op[ [[+]] ])
            push(1)
            push({0,1})
            push(x)
            pcall(M.op[ [[*]] ])
            pcall(M.op[ [[-]] ])
            pcall(M.op[ [[/]] ])
            pcall(M.op[ [[ln]] ])
            pcall(M.op[ [[*]] ])
        else
            push(math.atan(x))
        end
    end,
    [ [[acsc]] ]  = function() -- Inverse cosecant
        pcall(M.op[ [[\]] ])
        pcall(M.op[ [[asin]] ])
    end,
    [ [[asec]] ]  = function() -- Inverse secant
        pcall(M.op[ [[\]] ])
        pcall(M.op[ [[acos]] ])
    end,
    [ [[acot]] ]  = function() -- Inverse cotangent
        pcall(M.op[ [[\]] ])
        pcall(M.op[ [[atan]] ])
    end,
    -- Hyperbolic Trigonometry ---------------------------------------------------------------------
    [ [[sinh]] ]  = function() -- Hyperbolic sine
        local x=pop()
        if math.isComplex(x) then
            push({math.cos(x[2])*math.sinh(x[1]), math.sin(x[2])*math.cosh(x[1])})
        elseif math.isReal(x) then
            push(math.sinh(x))
        end
    end,
    [ [[cosh]] ]  = function() -- Hyperbolic cosine
        local x=pop()
        if math.isComplex(x) then
            push({math.cos(x[2])*math.cosh(x[1]), math.sin(x[2])*math.sinh(x[1])})
        elseif math.isReal(x) then
            push(math.cosh(x))
        end
    end,
    [ [[tanh]] ]  = function() -- Hyperbolic tangent
        local x=pop()
        push(x)
        pcall(M.op[ [[sinh]] ])
        push(x)
        pcall(M.op[ [[cosh]] ])
        pcall(M.op[ [[/]] ])
    end,
    [ [[csch]] ]  = function() -- Hyperbolic cosecant
        pcall(M.op[ [[sinh]] ])
        pcall(M.op[ [[\]] ])
    end,
    [ [[sech]] ]  = function() -- Hyperbolic secant
        pcall(M.op[ [[cosh]] ])
        pcall(M.op[ [[\]] ])
    end,
    [ [[coth]] ]  = function() -- Hyperbolic cotangent
        pcall(M.op[ [[tanh]] ])
        pcall(M.op[ [[\]] ])
    end,
    -- Inverse Hyperbolic Trigonometry -------------------------------------------------------------
    [ [[asinh]] ] = function() -- Inverse hyperbolic sine
        local x=pop()
        push(x)
        push(x)
        push(x)
        pcall(M.op[ [[*]] ])
        push(1)
        pcall(M.op[ [[+]] ])
        pcall(M.op[ [[sqrt]] ])
        pcall(M.op[ [[+]] ])
        pcall(M.op[ [[ln]] ])
    end,
    [ [[acosh]] ] = function() -- Inverse hyperbolic cosine
        local x=pop()
        push(x)
        push(x)
        push(x)
        pcall(M.op[ [[*]] ])
        push(1)
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[sqrt]] ])
        pcall(M.op[ [[+]] ])
        pcall(M.op[ [[ln]] ])
    end,
    [ [[atanh]] ] = function() -- Inverse hyperbolic tangent
        local x=pop()
        push(1)
        push(x)
        pcall(M.op[ [[+]] ])
        push(1)
        push(x)
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[/]] ])
        pcall(M.op[ [[ln]] ])
        push(2)
        pcall(M.op[ [[/]] ])
    end,
    [ [[acsch]] ] = function() -- Inverse hyperbolic cosecant
        local x=pop()
        push(1)
        push(x)
        push(x)
        pcall(M.op[ [[*]] ])
        pcall(M.op[ [[+]] ])
        pcall(M.op[ [[sqrt]] ])
        push(1)
        pcall(M.op[ [[+]] ])
        push(x)
        pcall(M.op[ [[/]] ])
        pcall(M.op[ [[ln]] ])
    end,
    [ [[asech]] ] = function() -- Inverse hyperbolic secant
        local x=pop()
        push(1)
        push(x)
        push(x)
        pcall(M.op[ [[*]] ])
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[sqrt]] ])
        push(1)
        pcall(M.op[ [[+]] ])
        push(x)
        pcall(M.op[ [[/]] ])
        pcall(M.op[ [[ln]] ])
    end,
    [ [[acoth]] ] = function() -- Inverse hyperbolic cotangent
        local x=pop()
        push(x)
        push(1)
        pcall(M.op[ [[+]] ])
        push(x)
        push(1)
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[/]] ])
        pcall(M.op[ [[ln]] ])
        push(2)
        pcall(M.op[ [[/]] ])
    end,
    -- Angle Conversion ----------------------------------------------------------------------------
    [ [[deg]] ]   = function() push(math.deg(pop())) end, -- convert x to degrees
    [ [[rad]] ]   = function() push(math.rad(pop())) end, -- convert x to radians

    -- #############################################################################################
    -- ##################################################################################### Bitwise
    -- #############################################################################################
    [ [[&]] ]     = function() push(bit.band(pop(),pop())) end, -- AND
    [ [[|]] ]     = function() push(bit.bor(pop(),pop())) end, -- OR
    [ [[^]] ]     = function() push(bit.bxor(pop(),pop())) end, -- XOR
    [ [[~]] ]     = function() push(bit.bnot(pop())) end, -- NOT
    [ [[<<]] ]    = function() local n=pop(); push(bit.lshift(pop(),n)) end, -- Left Shift
    [ [[>>]] ]    = function() local n=pop(); push(bit.rshift(pop(),n)) end, -- Right Shift


    -- #############################################################################################
    -- ################################################################################### Constants
    -- #############################################################################################
    [ [[pi]] ]  = function() push(math.pi);            M.lastx = M.stack[#M.stack] end, -- 3.141592653...
    [ [[e]] ]   = function() push(math.exp(1));        M.lastx = M.stack[#M.stack] end, -- 2.718281828...
    [ [[phi]] ] = function() push((1+math.sqrt(5))/2); M.lastx = M.stack[#M.stack] end, -- 1.618033989
    [ [[i]] ]   = function() push({0,1});              M.lastx = M.stack[#M.stack] end, -- the imaginary unit value


    -- #############################################################################################
    -- ####################################################################################### Other
    -- #############################################################################################
    [ [[hrs]] ]   = function() push((pop() / 60 + pop()) / 60 + pop()) end, -- Convert Z:Y:X to hours
    [ [[hms]] ]   = function()  -- Convert X hours to Z:Y:X
        local x=pop()
        for _=1,2 do
            local t=x<0 and math.ceil(x) or math.floor(x)
            push(t)
            x=60*(x-t)
        end
        push(x)
    end,
    [ [[gcd]] ] = function()
        local x,y = pop(),pop()
        if not math.isInt(x) or not math.isInt(y) then
            push(math.nan)
            return
        end
        x,y = math.abs(x),math.abs(y)
        local t
        while y ~= 0 do
            t = y
            y = math.fmod(x, y)
            x = t
        end
        push(x)
    end,
    [ [[lcm]] ] = function()
        local x,y = pop(),pop()
        if not math.isInt(x) or not math.isInt(y) then
            push(math.nan)
            return
        end
        if x == 0 and y == 0 then
            push(0)
            return
        end
        push(y)
        push(x)
        pcall(M.op[ [[gcd]] ])
        local gcd = pop()
        push(math.abs(x) / gcd * math.abs(y))
    end,

    -- #############################################################################################
    -- ################################################################### Bases (Reading & Writing)
    -- #############################################################################################
    [ [[bin]] ] = function() M.base = 2 end,  -- Change output to binary
    [ [[hex]] ] = function() M.base = 16 end, -- Change output to hexadecimal
    [ [[dec]] ] = function() M.base = 10 end, -- Change output to decimal

    -- #############################################################################################
    -- ################################################################# Memory & Stack Manipulation
    -- #############################################################################################
    [ [[sto]] ]  = function() local x = pop(); M.memory = x; push(x); end, -- store X in memory
    [ [[rcl]] ]  = function() push(M.memory); end, -- recall memory to the stack
    [ [[m+]] ]   = function() local x = pop(); M.memory = M.memory + x; push(x); end, -- add X to memory
    [ [[m-]] ]   = function() local x = pop(); M.memory = M.memory - x; push(x); end, -- subtract X from memory
    [ [[xy]] ]   = function() local x,y = pop(), pop(); push(x); push(y); end, -- swap X and Y
    [ [[x]] ]    = function() push(M.lastx); end, -- swap X and Y
    [ [[drop]] ] = function() pop(); end, -- drop X off the stack

    -- #############################################################################################
    -- ################################################################################## Statistics
    -- #############################################################################################
    [ [[!]] ] = function()  -- Factorial
        local x = pop();
        if not math.isInt(x) or x < 0 then
            push(math.nan)
            return
        end

        local f = 1
        for i=1,x do
            f = f * i
        end
        push(f)
    end,
    [ [[perm]] ] = function()  -- Permutations of Y things taken X at a time
        local x,y = pop(),pop()
        push(y)
        pcall(M.op[ [[!]] ])
        push(y)
        push(x)
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[!]] ])
        pcall(M.op[ [[/]] ])
    end,
    [ [[comb]] ] = function()  -- Combinations of Y things taken X at a time
        local x,y = pop(),pop()
        push(y)
        pcall(M.op[ [[!]] ])
        push(y)
        push(x)
        pcall(M.op[ [[-]] ])
        pcall(M.op[ [[!]] ])
        push(x)
        pcall(M.op[ [[!]] ])
        pcall(M.op[ [[*]] ])
        pcall(M.op[ [[/]] ])
    end,
    [ [[n]] ] = function()  -- Count of all numbers on stack
        M.stack = {#M.stack}
    end,
    [ [[sum]] ] = function()  -- Sum of all numbers on stack
        local n = #M.stack
        for _ = 1,n-1 do
            pcall(M.op[ [[+]] ])
        end
    end,
    [ [[ssq]] ] = function()  -- Sum of squares of all numbers on stack
        local n = #M.stack
        push(2)
        pcall(M.op[ [[**]] ])
        for _ = 1,n-1 do
            pcall(M.op[ [[xy]] ])
            push(2)
            pcall(M.op[ [[**]] ])
            pcall(M.op[ [[+]] ])
        end
    end,
    [ [[mean]] ] = function()  -- Mean average of all numbers on stack
        local n = #M.stack
        pcall(M.op[ [[sum]] ])
        push(n)
        pcall(M.op[ [[/]] ])
    end,
    [ [[std]] ] = function()  -- Standard deviation of all numbers on stack
        local s = {unpack(M.stack)}
        local n = #M.stack

        pcall(M.op[ [[mean]] ])
        local mean = M.stack[#M.stack]
        if math.isComplex(mean) then
            M.stack = {math.nan}
        else
            local sum = 0
            for i = 1,n do
                sum = sum + (s[i] - mean) ^ 2
            end
            M.stack = {math.sqrt(sum / (n-1))}
        end
    end,
}

return M
