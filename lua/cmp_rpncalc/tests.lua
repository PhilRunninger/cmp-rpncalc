M = {}

local printAll = false

local mockRequest = function(str)
    return { context = { cursor_before_line = str, cursor = { row = 1, col = 1 } } }
end

local assertEqual = function(expression, expected, tolerance)
    local msg = type(expected) == 'table'
        and string.format('    %25s  should equal {%s, %s} ', expression, expected[1], expected[2])
        or string.format('    %25s  should equal  %s ', expression, expected)
    msg = msg .. (tolerance
        and string.format('± %-15s', tolerance)
        or  '')
    local pass = false
    local checkResult = function(response)
        local result = response.items[1].textEdit.newText
        if type(expected) == 'string' then
            local s,e = vim.regex([[^]]..expected..[[$]]):match_str(result)
            pass = s and e
        else
            tolerance = tolerance or 0
            if type(expected) == 'table' then
                -- Split complex into real and imaginary: "1.23+4.5i" -> {"1.23", "+4.5"}
                local parts = vim.fn.split(result, '\\(\\ze[+-]\\|i\\)')
                -- vim.pretty_print(parts)
                -- Side effect: it also splits mantissas from exponents: "1.2e-6+9.9e-8i" -> {"1.2e", "-6", "+9.9e", "-8"}
                -- If that happens, smash them back together again: -> {"1.2e-6", "+9.9e-8"}
                local i = 1
                while i < #parts do
                    if string.match(parts[i],'[Ee]$') then
                        parts[i] = parts[i] .. parts[i+1]
                        table.remove(parts, i+1)
                    end
                    i = i + 1
                end
                -- vim.pretty_print(parts, expected)

                pass = #parts == #expected and
                    math.abs(tonumber(parts[1])-expected[1]) <= tolerance and
                    math.abs(tonumber(parts[2])-expected[2]) <= tolerance
            else
                pass = math.abs(tonumber(result)-expected) <= tolerance
            end
        end
        msg = msg .. (pass and '' or '  Got "' .. result .. '"')
    end
    require('cmp_rpncalc').complete(0, mockRequest(expression), checkResult)
    if printAll or not pass then
        print(pass and '    pass' or '    FAIL', msg)
    end
    return pass
end

M.rerun = function(verbose)
    vim.schedule(function()
        package.loaded['cmp_rpncalc'] = nil
        package.loaded['cmp_rpncalc.tests'] = nil
        require('cmp_rpncalc.tests').run(verbose)
        vim.cmd('messages')
    end)
end

M.run = function(verbose)
    printAll = verbose and true or false
    local passedTests = 0
    local failedTests = 0

    local count = function(pass)
        passedTests = passedTests + (pass and 1 or 0)
        failedTests = failedTests + (pass and 0 or 1)
    end

    print('No Operator (return the input) ==============================================')
    count(assertEqual( [[12]],       [[12]] ))
    count(assertEqual( [[1 2 3 4]],  [[1 2 3 4]] ))

    print('Basic Arithmetic ============================================================')
    count(assertEqual( [[3 2 +]],     5))   -- Addtion
    count(assertEqual( [[3.1 2.2 +]], 5.3))
    count(assertEqual( [[13 2 -]],    11))  -- Subtraction
    count(assertEqual( [[1.3 2 -]],   -0.7))
    count(assertEqual( [[14 3 *]],    42))  -- Multiplication
    count(assertEqual( [[1.4 .3 *]],  0.42))
    count(assertEqual( [[24 8 /]],    3))   -- Division
    count(assertEqual( [[8 24 /]],    0.333333333333, 1e-6))
    count(assertEqual( [[7 0 /]],     'inf'))
    count(assertEqual( [[0 0 /]],     'nan'))
    count(assertEqual( [[23 5 div]],  4))   -- Integer part of division
    count(assertEqual( [[-23 5 div]], -4))
    count(assertEqual( [[23 5 %]],    3))   -- Remainder of division
    count(assertEqual( [[23 -5 %]],   -2))
    count(assertEqual( [[-23 5 %]],   2))
    count(assertEqual( [[-23 -5 %]],  -3))
    count(assertEqual( [[7 abs]],     7))   -- Absolute Value
    count(assertEqual( [[-7 abs]],    7))
    count(assertEqual( [[-8 chs]],    8))   -- Change Sign
    count(assertEqual( [[8 chs]],     -8))

    print('Rounding ====================================================================')
    count(assertEqual( [[12.3 floor]],  12 ))  -- Floor - round down to nearest integer
    count(assertEqual( [[-12.3 floor]], -13 ))
    count(assertEqual( [[12.3 ceil]],   13 ))  -- Ceiling - round up to nearest integer
    count(assertEqual( [[-12.3 ceil]],  -12 ))
    count(assertEqual( [[12.3 round]],  12 ))  -- Round to nearest integer
    count(assertEqual( [[-12.3 round]], -12 ))
    count(assertEqual( [[12.7 round]],  13 ))
    count(assertEqual( [[-12.7 round]], -13 ))
    count(assertEqual( [[12.7 trunc]],  12 ))  -- Round toward zero
    count(assertEqual( [[-12.7 trunc]], -12 ))

    print('Powers & Logs ===============================================================')
    count(assertEqual( [[2 exp]],       7.3890560989, 1e-6))  -- Raise e to the x power
    count(assertEqual( [[0 exp]],       1))
    count(assertEqual( [[0.1 exp]],     1.1051709180, 1e-6))
    count(assertEqual( [[120 log]],     4.7874917427, 1e-6))  -- Natural log of x
    count(assertEqual( [[0 log]],       '-inf'))
    count(assertEqual( [[625 5 logx]],  4))  -- Log (base x) of y
    count(assertEqual( [[625 -5 logx]], 'nan'))
    count(assertEqual( [[-625 5 logx]], 'nan'))
    count(assertEqual( [[1000 log10]],  3))  -- Log (base 10) of x
    count(assertEqual( [[12345 log10]], 4.0914910942, 1e-6))
    count(assertEqual( [[1024 log2]],   10))  -- Log (base 2) of x
    count(assertEqual( [[13 log2]],     3.7004397181, 1e-6))
    count(assertEqual( [[36 sqrt]],     6))  -- Square Root
    count(assertEqual( [[23.1 sqrt]],   4.8062459362, 1e-6))
    count(assertEqual( [[2 3 **]],      8))  -- Exponentiation
    count(assertEqual( [[-12 4 **]],    20736))
    count(assertEqual( [[0 0 **]],      'nan'))
    count(assertEqual( [[12 -0.25 **]], 0.5372849659, 1e-6))
    count(assertEqual( [[10 \]],        0.1))  -- Reciprocal
    count(assertEqual( [[0 \]],         'inf'))

    print('Trigonometry ================================================================')
    count(assertEqual( [[pi 2 / deg]], 90,           1e-6))  -- convert x to degrees
    count(assertEqual( [[90 rad]],     1.5707963267, 1e-6))  -- convert x to radians

    count(assertEqual( [[30 rad sin]], 0.5 ))  -- Sine
    count(assertEqual( [[60 rad cos]], 0.5 ))  -- Cosine
    count(assertEqual( [[45 rad tan]], 1.0 ))  -- Tangent
    -- count(assertEqual( [[90 rad tan]], 'inf' ))  -- The actual is VERY large, but not inf.
    count(assertEqual( [[30 rad csc]], 2.0 ))  -- Cosecant
    count(assertEqual( [[60 rad sec]], 2.0 ))  -- Secant
    count(assertEqual( [[45 rad cot]], 1.0 ))  -- Cotangent
    count(assertEqual( [[0 cot]],      'inf' ))  -- Cotangent

    count(assertEqual( [[0.5 asin deg]], 30 ))  -- Inverse sine
    count(assertEqual( [[10 asin]],      'nan' ))
    count(assertEqual( [[0.5 acos deg]], 60 ))  -- Inverse cosine
    count(assertEqual( [[-10 acos]],     'nan' ))
    count(assertEqual( [[1 atan deg]],   45 ))    -- Inverse Tangent
    count(assertEqual( [[2.0 acsc deg]], 30 ))  -- Inverse cosecant
    count(assertEqual( [[0 acsc]],       'nan' ))  -- Inverse cosecant
    count(assertEqual( [[2.0 asec deg]], 60 ))  -- Inverse secant
    count(assertEqual( [[0 asec]],       'nan' ))  -- Inverse secant
    count(assertEqual( [[1 acot deg]],   45 ))  -- Inverse cotangent

    count(assertEqual( [[2 sinh]],             3.6268604078, 1e-6 )) -- Hyperbolic sine
    count(assertEqual( [[4 cosh]],             27.308232836, 1e-6 )) -- Hyperbolic cosine
    count(assertEqual( [[-0.5 tanh]],          -0.462117157, 1e-6 )) -- Hyperbolic tangent
    count(assertEqual( [[3.6268604079 asinh]], 2.0, 1e-6 )) -- Inverse hyperbolic sine
    count(assertEqual( [[27.30823284 acosh]],  4.0, 1e-6 )) -- Inverse hyperbolic cosine
    count(assertEqual( [[0 acosh]],            'nan' ))
    count(assertEqual( [[-0.462117157 atanh]], -0.5, 1e-6 )) -- Inverse hyperbolic tangent
    count(assertEqual( [[1 atanh]],            'inf' ))
    count(assertEqual( [[-1 atanh]],           '-inf' ))
    count(assertEqual( [[10 atanh]],           'nan' ))

    count(assertEqual( [[2 csch]],              0.27572056, 1e-6 ))  -- Hyperbolic cosecant
    count(assertEqual( [[0 csch]],              'inf' ))
    count(assertEqual( [[-5 sech]],             0.013475282, 1e-6 ))  -- Hyperbolic secant
    count(assertEqual( [[0 sech]],              1 ))
    count(assertEqual( [[0.5 coth]],            2.16395341373, 1e-6 ))  -- Hyperbolic cotangent
    count(assertEqual( [[0 coth]],              'inf' ))
    count(assertEqual( [[0.27572056 acsch]],    2.0, 1e-6 ))  -- Inverse hyperbolic cosecant
    count(assertEqual( [[0 acsch]],             'inf' ))
    count(assertEqual( [[0.013475282 asech]],   5.0, 1e-6 ))  -- Inverse hyperbolic secant
    count(assertEqual( [[-1 asech]],            'nan' ))
    count(assertEqual( [[2.16395341373 acoth]], 0.5, 1e-6 ))  -- Inverse hyperbolic cotangent
    count(assertEqual( [[0 acoth]],             'nan' ))

    print('Bitwise =====================================================================')
    count(assertEqual( [[60 13 &]], 12 ))   -- AND
    count(assertEqual( [[60 13 |]], 61 ))   -- OR
    count(assertEqual( [[60 13 ^]], 49 ))   -- XOR
    count(assertEqual( [[60 ~]],    -61 ))  -- NOT
    count(assertEqual( [[60 2 <<]], 240 ))  -- Left Shift
    count(assertEqual( [[60 2 >>]], 15 ))   -- Right Shift

    print('Constants ===================================================================')
    count(assertEqual( [[pi]],  3.1415926535, 1e-6 ))  -- 3.141592653....
    count(assertEqual( [[e]],   2.7182818284, 1e-6 ))  -- 2.718281828...
    count(assertEqual( [[phi]], 1.6180339887, 1e-6 ))  -- golden ratio
    count(assertEqual( [[i]],   {0,1} ))

    print('Other =======================================================================')
    count(assertEqual( [[3 20 15 hrs]], 3.3375 ))  -- Convert Z:Y:X to hours
    count(assertEqual( [[3.3375 hms]], [[3 20 15]] ))  -- Convert X hours to Z:Y:X

    print('AGAIN, BUT WITH COMPLEX NUMBERS ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~')

    print('No Operator (return the input) ==============================================')
    count(assertEqual( [[12,2]],       {12,2} ))
    count(assertEqual( [[1,-2 3,4]],  [[1-2i 3+4i]] ))

    print('Basic Arithmetic ============================================================')
    count(assertEqual( [[3,1  2,6 +]],    {5,7} ))   -- Addtion
    count(assertEqual( [[3.5  2,6 +]],    {5.5,6} ))
    count(assertEqual( [[3,1  6 +]],      {9,1} ))
    count(assertEqual( [[13,4 2,2 -]],    {11,2} ))  -- Subtraction
    count(assertEqual( [[13   2,2 -]],    {11,-2} ))
    count(assertEqual( [[13,4 2 -]],      {11,4} ))
    count(assertEqual( [[1,4  3,2 *]],    {-5,14} ))  -- Multiplication
    count(assertEqual( [[4    3,2 *]],    {12,8} ))
    count(assertEqual( [[1,4  3 *]],      {3,12} ))
    count(assertEqual( [[2,4  2 /]],      {1,2} ))   -- Division
    count(assertEqual( [[2    4,2 /]],    {0.4,-0.2} ))
    count(assertEqual( [[3,-1 4,2 /]],    {0.5,-0.5} ))

    count(assertEqual( [[3,4 abs]],     5 ))   -- Absolute Value

    count(assertEqual( [[1,1 arg]],     0.78539816339745, 1e-6 ))  -- Arg
    count(assertEqual( [[-3,1 arg]],     2.8198420991932, 1e-6 ))
    count(assertEqual( [[-3,-2 arg]],     -2.5535900500422, 1e-6 ))
    count(assertEqual( [[2,-1 arg]],     -0.46364760900081, 1e-6 ))
    count(assertEqual( [[1 arg]],       'nan' ))

    count(assertEqual( [[-8,2 chs]],    {8,-2} ))   -- Change Sign

    print('Rounding ====================================================================')
    count(assertEqual( [[12.3,4.2 floor]],   {12,4} ))  -- Floor - round down to nearest integer
    count(assertEqual( [[-12.3,-4.2 floor]], {-13,-5} ))
    count(assertEqual( [[12.3,4.2 ceil]],    {13,5} ))  -- Ceiling - round up to nearest integer
    count(assertEqual( [[-12.3,-4.2 ceil]],  {-12,-4} ))
    count(assertEqual( [[12.3,4.7 round]],   {12,5} ))  -- Round to nearest integer
    count(assertEqual( [[-12.3,-4.7 round]], {-12,-5} ))
    count(assertEqual( [[12.7,4.3 round]],   {13,4} ))
    count(assertEqual( [[-12.7,-4.3 round]], {-13,-4} ))
    count(assertEqual( [[12.7,4.3 trunc]],   {12,4} ))  -- Round toward zero
    count(assertEqual( [[-12.7,-4.3 trunc]], {-12,-4} ))

    print('Powers & Logs ===============================================================')
    count(assertEqual( [[2,1 exp]],      {3.992324048,6.217676312}, 1e-6 )) -- Raise e to the x power
    count(assertEqual( [[2,3 log]],      {1.282474678,0.982793723}, 1e-6 ))  -- Natural log of x
    count(assertEqual( [[2,3 log10]],    {0.556971676,0.426821891}, 1e-6 ))  -- Log (base 10) of x
    count(assertEqual( [[2,3 log2]],     {1.850219859,1.417871631}, 1e-6 ))  -- Log (base 2) of x
    count(assertEqual( [[2,3 1,2 logx]], {1.131731655,-0.335771298}, 1e-6 ))  -- Log (base x) of y
    count(assertEqual( [[-4 sqrt]],      {0,2}, 1e-6))  -- Square root
    count(assertEqual( [[2,3.1 sqrt]],   {1.6865902,0.91901396}, 1e-6 ))
    count(assertEqual( [[0,1 2 **]],     {-1,0}, 1e-6 ))  -- Exponentiation
    count(assertEqual( [[0,1 3 **]],     {0,-1}, 1e-6 ))
    count(assertEqual( [[1,1 2 **]],     {0,2}, 1e-6 ))
    count(assertEqual( [[3 1,-2 **]],    {-1.7587648,-2.4303798}, 1e-6))
    count(assertEqual( [[-4,3 1,-2 **]], {555.3814991,-487.8784553}, 1e-6))
    count(assertEqual( [[-7 3.3 **]],    {-361.4449966, -497.4863586}, 1e-6))
    count(assertEqual( [[0,0 0 **]],     'nan' ))
    count(assertEqual( [[0 0,0 **]],     'nan' ))
    count(assertEqual( [[0,0 0,0 **]],   'nan' ))
    count(assertEqual( [[0,0 \]],        'inf' ))
    count(assertEqual( [[2,3 \]],        {2/13, -3/13}, 1e-6))

    print('Trigonometry ================================================================')
    count(assertEqual( [[1,1 sin]], {1.298457581,0.634963915}, 1e-6))
    count(assertEqual( [[1,1 cos]], {0.833730025,-0.988897706}, 1e-6))
    count(assertEqual( [[1,1 tan]], {0.271752585,1.083923327}, 1e-6))
    count(assertEqual( [[1,1 csc]], {0.621518017,-0.303931002}, 1e-6))
    count(assertEqual( [[1,1 sec]], {0.498337031,0.591083842}, 1e-6))
    count(assertEqual( [[1,1 cot]], {0.217621562,-0.868014143}, 1e-6))

    count(assertEqual( [[1,2 sinh]], {-0.489056259,1.403119251}, 1e-6))
    count(assertEqual( [[1,2 cosh]], {-0.642148716,1.068607421}, 1e-6))
    count(assertEqual( [[1,2 tanh]], {1.166736257,-0.243458201}, 1e-6))
    count(assertEqual( [[1,2 csch]], {-0.221500931,-0.635493799}, 1e-6))
    count(assertEqual( [[1,2 sech]], {-0.413149344,-0.687527439}, 1e-6))
    count(assertEqual( [[1,2 coth]], {0.821329797,0.171383613}, 1e-6))

    count(assertEqual( [[1,1 asin]], {0.666239432,1.061275062}, 1e-6))
    count(assertEqual( [[1,1 acos]], {0.904556894,-1.061275062}, 1e-6))
    count(assertEqual( [[1,1 atan]], {1.017221968,0.402359478}, 1e-6))
    count(assertEqual( [[1,1 acsc]], {0.452278447,-0.530637531}, 1e-6))
    count(assertEqual( [[1,1 asec]], {1.118517880,0.530637531}, 1e-6))
    count(assertEqual( [[1,1 acot]], {0.553574359,-0.402359478}, 1e-6))

    print(string.format('\n%4d test(s) passed.  %4d test(s) failed.', passedTests, failedTests)) end
return M
