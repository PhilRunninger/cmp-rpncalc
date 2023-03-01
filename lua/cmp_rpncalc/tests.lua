M = {}

local printAll = false

local mockRequest = function(str)
    return { context = { cursor_before_line = str, cursor = { row = 1, col = 1 } } }
end

local assertEqual = function(expression, expected, tolerance)
    local msg = tolerance
        and string.format('    %25s  should equal  %15s ± %-15s', expression, expected, tolerance)
        or  string.format('    %25s  should equal  %15s', expression, expected)
    local pass = false
    local checkResult = function(response)
        local result = response.items[1].textEdit.newText
        if type(expected) == 'string' then
            pass = result == expected
        else
            tolerance = tolerance or 0
            pass = (expected-tolerance <= tonumber(result) and tonumber(result) <= expected+tolerance)
        end
        msg = msg .. (pass and '' or ('  Got ' .. result))
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

    print('Basic Arithmetic ============================================================')
    count(assertEqual('3 2 +',     5))   -- Addtion
    count(assertEqual('3.1 2.2 +', 5.3))
    count(assertEqual('13 2 -',    11))  -- Subtraction
    count(assertEqual('1.3 2 -',   -0.7))
    count(assertEqual('14 3 *',    42))  -- Multiplication
    count(assertEqual('1.4 .3 *',  0.42))
    count(assertEqual('24 8 /',    3))   -- Division
    count(assertEqual('8 24 /',    0.333333333333, 1e-6))
    count(assertEqual('7 0 /',     'inf'))
    count(assertEqual('0 0 /',     'nan'))
    count(assertEqual('23 5 div',  4))   -- Integer part of division
    count(assertEqual('-23 5 div', -4))
    count(assertEqual('23 5 %',    3))   -- Remainder of division
    count(assertEqual('23 -5 %',   -2))
    count(assertEqual('-23 5 %',   2))
    count(assertEqual('-23 -5 %',  -3))
    count(assertEqual('7 abs',     7))   -- Absolute Value
    count(assertEqual('-7 abs',    7))
    count(assertEqual('-8 chs',    8))   -- Change Sign
    count(assertEqual('8 chs',     -8))

    print('Rounding ====================================================================')
    count(assertEqual('12.3 floor',  12))  -- Floor - round down to nearest integer
    count(assertEqual('-12.3 floor', -13))
    count(assertEqual('12.3 ceil',   13))  -- Ceiling - round up to nearest integer
    count(assertEqual('-12.3 ceil',  -12))
    count(assertEqual('12.3 round',  12))  -- Round to nearest integer
    count(assertEqual('-12.3 round', -12))
    count(assertEqual('12.7 round',  13))
    count(assertEqual('-12.7 round', -13))
    count(assertEqual('12.7 trunc',  12))  -- Round toward zero
    count(assertEqual('-12.7 trunc', -12))

    print('Powers & Logs ===============================================================')
    count(assertEqual('2 exp',       7.3890560989, 1e-6))  -- Raise e to the x power
    count(assertEqual('0 exp',       1))
    count(assertEqual('0.1 exp',     1.1051709180, 1e-6))
    count(assertEqual('120 log',     4.7874917427, 1e-6))  -- Natural log of x
    count(assertEqual('0 log',       '-inf'))
    count(assertEqual('625 5 logx',  4))  -- Log y of x
    count(assertEqual('625 -5 logx', 'nan'))
    count(assertEqual('-625 5 logx', 'nan'))
    count(assertEqual('1000 log10',  3))  -- Log (base 10) of x
    count(assertEqual('12345 log10', 4.0914910942, 1e-6))
    count(assertEqual('1024 log2',   10))  -- Log (base 2) of x
    count(assertEqual('13 log2',     3.7004397181, 1e-6))
    count(assertEqual('36 sqrt',     6))  -- Square Root
    count(assertEqual('-4 sqrt',     'nan'))
    count(assertEqual('23.1 sqrt',   4.8062459362, 1e-6))
    count(assertEqual('2 3 **',      8))  -- Exponentiation
    count(assertEqual('-12 4 **',    20736))
    count(assertEqual('-7 3.3 **',   'nan'))
    count(assertEqual('0 0 **',      'nan'))
    count(assertEqual('12 -0.25 **', 0.5372849659, 1e-6))
    count(assertEqual('10 \\',       0.1))  -- Reciprocal
    count(assertEqual('0 \\',        'inf'))

    print('Trigonometry ================================================================')
    count(assertEqual('1.5707963267 deg', 90,           1e-6))  -- convert x to degrees
    count(assertEqual('90 rad',           1.5707963267, 1e-6))  -- convert x to radians

    count(assertEqual('30 rad sin', 0.5))  -- Sine
    count(assertEqual('60 rad cos', 0.5))  -- Cosine
    count(assertEqual('45 rad tan', 1.0))  -- Tangent
    -- count(assertEqual('90 rad tan', 'inf'))  -- The actual is VERY large, but not inf.
    count(assertEqual('30 rad csc', 2.0))  -- Cosecant
    count(assertEqual('60 rad sec', 2.0))  -- Secant
    count(assertEqual('45 rad cot', 1.0))  -- Cotangent
    count(assertEqual('0 cot',      'inf'))  -- Cotangent

    count(assertEqual('0.5 asin deg', 30.0))  -- Inverse sine
    count(assertEqual('10 asin',      'nan'))
    count(assertEqual('0.5 acos deg', 60.0))  -- Inverse cosine
    count(assertEqual('-10 acos',     'nan'))
    count(assertEqual('1 atan deg',   45.0))    -- Inverse Tangent
    count(assertEqual('2.0 acsc deg', 30.0))  -- Inverse cosecant
    count(assertEqual('0 acsc',       'nan'))  -- Inverse cosecant
    count(assertEqual('2.0 asec deg', 60.0))  -- Inverse secant
    count(assertEqual('0 asec',       'nan'))  -- Inverse secant
    count(assertEqual('1 acot deg',   45.0))  -- Inverse cotangent

    count(assertEqual('2 sinh',             3.6268604079, 1e-6)) -- Hyperbolic sine
    count(assertEqual('4 cosh',             27.308232836, 1e-6)) -- Hyperbolic cosine
    count(assertEqual('-0.5 tanh',          -0.462117157, 1e-6)) -- Hyperbolic tangent
    count(assertEqual('3.6268604079 asinh', 2.0,          1e-6)) -- Inverse hyperbolic sine
    count(assertEqual('27.30823284 acosh',  4.0,          1e-6)) -- Inverse hyperbolic cosine
    count(assertEqual('0 acosh',            'nan'))
    count(assertEqual('-0.462117157 atanh', -0.5,         1e-6)) -- Inverse hyperbolic tangent
    count(assertEqual('1 atanh',            'inf'))
    count(assertEqual('-1 atanh',           '-inf'))
    count(assertEqual('10 atanh',           'nan'))

    count(assertEqual('2 csch',              0.27572056,    1e-6))  -- Hyperbolic cosecant
    count(assertEqual('0 csch',              'inf'))
    count(assertEqual('-5 sech',             0.013475282,   1e-6))  -- Hyperbolic secant
    count(assertEqual('0 sech',              1.0))
    count(assertEqual('0.5 coth',            2.16395341373, 1e-6))  -- Hyperbolic cotangent
    count(assertEqual('0 coth',              'inf'))
    count(assertEqual('0.27572056 acsch',    2.0,           1e-6))  -- Inverse hyperbolic cosecant
    count(assertEqual('0 acsch',             'inf'))
    count(assertEqual('0.013475282 asech',   5.0,           1e-6))  -- Inverse hyperbolic secant
    count(assertEqual('-1 asech',            'nan'))
    count(assertEqual('2.16395341373 acoth', 0.5,           1e-6))  -- Inverse hyperbolic cotangent
    count(assertEqual('0 acoth',             'nan'))

    print('Bitwise =====================================================================')
    count(assertEqual('60 13 &', 12))   -- AND
    count(assertEqual('60 13 |', 61))   -- OR
    count(assertEqual('60 13 ^', 49))   -- XOR
    count(assertEqual('60 ~',    -61))  -- NOT
    count(assertEqual('60 2 <<', 240))  -- Left Shift
    count(assertEqual('60 2 >>', 15))   -- Right Shift

    print('Constants ===================================================================')
    count(assertEqual('pi',  3.1415926535, 1e-6))  -- 3.141592653....
    count(assertEqual('e',   2.7182818284, 1e-6))  -- 2.718281828...
    count(assertEqual('phi', 1.6180339887, 1e-6))  -- golden ratio

    print('Other =======================================================================')
    count(assertEqual('3 20 15 hrs', 3.3375))  -- Convert Z:Y:X to hours
    count(assertEqual('3.3375 hms', '3 20 15'))  -- Convert X hours to Z:Y:X

    print(string.format('\n%4d test(s) passed.  %4d test(s) failed.', passedTests, failedTests))
end

return M
