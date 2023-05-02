-- vim: set foldmethod=marker
--
-- To run the tests, use these commands:
--
-- :wa|mess clear|lua require('cmp_rpncalc.tests').rerun(false)
--          - false prints only failure messages
--          - true prints all messages
-- :messages

M = {}  -- Setup {{{1

local printAll = false

local mockRequest = function(str)  -- {{{2
    return { context = { cursor_before_line = str, cursor = { row = 1, col = 1 } } }
end

local assert = function(expression, expected, tolerance)  -- {{{2
    local msg = type(expected) == 'table'
        and string.format('    %25s  should equal {%s, %s} ', expression, expected[1], expected[2])
        or string.format('    %25s  should equal  %s ', expression, expected)
    msg = msg .. (tolerance
        and string.format('± %-15s', tolerance)
        or  '')
    local pass = false
    local checkResult = function(response)
        -- vim.pretty_print('response', response)
        local result = ''
        if next(response) == nil then
            result = ''
            pass = false
        else
            result = response.items[1].textEdit.newText
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
        end
        msg = msg .. (pass and '' or '  Got "' .. result .. '"')
    end
    require('cmp_rpncalc').complete(0, mockRequest(expression), checkResult)
    if printAll or not pass then
        print(pass and '    pass' or '    FAIL', msg)
    end
    return pass
end

M.rerun = function(verbose)  -- {{{2
    -- Rerun the tests after reloading (and recompiling) the source and test code.
    vim.schedule(function()
        package.loaded['cmp_rpncalc'] = nil
        package.loaded['cmp_rpncalc.tests'] = nil
        require('cmp_rpncalc.tests').run(verbose)
    end)
end

M.run = function(verbose) -- Unit Tests {{{1
    printAll = verbose and true or false
    local passedTests = 0
    local failedTests = 0

    local tally = function(pass)
        passedTests = passedTests + (pass and 1 or 0)
        failedTests = failedTests + (pass and 0 or 1)
    end

    print('No Operator (return the input) ==============================================')
    tally(assert( [[12]],       [[12]] ))
    tally(assert( [[1 2 3 4]],  [[1 2 3 4]] ))

    print('Basic Arithmetic ============================================================')
    tally(assert( [[3 2 +]],     5))   -- Addtion
    tally(assert( [[3.1 2.2 +]], 5.3))
    tally(assert( [[13 2 -]],    11))  -- Subtraction
    tally(assert( [[1.3 2 -]],   -0.7))
    tally(assert( [[14 3 *]],    42))  -- Multiplication
    tally(assert( [[1.4 .3 *]],  0.42))
    tally(assert( [[24 8 /]],    3))   -- Division
    tally(assert( [[8 24 /]],    0.333333333333, 1e-6))
    tally(assert( [[7 0 /]],     'Infinity'))
    tally(assert( [[0 0 /]],     'NaN'))
    tally(assert( [[23 5 div]],  4))   -- Integer part of division
    tally(assert( [[-23 5 div]], -4))
    tally(assert( [[23 5 %]],    3))   -- Remainder of division
    tally(assert( [[23 -5 %]],   -2))
    tally(assert( [[-23 5 %]],   2))
    tally(assert( [[-23 -5 %]],  -3))
    tally(assert( [[7 abs]],     7))   -- Absolute Value
    tally(assert( [[-7 abs]],    7))
    tally(assert( [[1 arg]],     0 ))  -- Arg
    tally(assert( [[0 arg]],     0 ))
    tally(assert( [[-1 arg]],    math.pi, 1e-6 ))
    tally(assert( [[-8 chs]],    8))   -- Change Sign
    tally(assert( [[8 chs]],     -8))

    print('Rounding ====================================================================')
    tally(assert( [[12.3 floor]],  12 ))  -- Floor - round down to nearest integer
    tally(assert( [[-12.3 floor]], -13 ))
    tally(assert( [[12.3 ceil]],   13 ))  -- Ceiling - round up to nearest integer
    tally(assert( [[-12.3 ceil]],  -12 ))
    tally(assert( [[12.3 round]],  12 ))  -- Round to nearest integer
    tally(assert( [[-12.3 round]], -12 ))
    tally(assert( [[12.7 round]],  13 ))
    tally(assert( [[-12.7 round]], -13 ))
    tally(assert( [[12.7 trunc]],  12 ))  -- Round toward zero
    tally(assert( [[-12.7 trunc]], -12 ))

    print('Powers & Logs ===============================================================')
    tally(assert( [[2 exp]],       7.3890560989, 1e-6))  -- Raise e to the x power
    tally(assert( [[0 exp]],       1))
    tally(assert( [[0.1 exp]],     1.1051709180, 1e-6))
    tally(assert( [[120 ln]],     4.7874917427, 1e-6))  -- Natural log of x
    tally(assert( [[0 ln]],       '-Infinity'))
    tally(assert( [[625 5 logx]],  4))  -- Log (base x) of y
    tally(assert( [[625 -5 logx]], 'NaN'))
    tally(assert( [[-625 5 logx]], 'NaN'))
    tally(assert( [[1000 log]],  3))  -- Log (base 10) of x
    tally(assert( [[12345 log]], 4.0914910942, 1e-6))
    tally(assert( [[1024 log2]],   10))  -- Log (base 2) of x
    tally(assert( [[13 log2]],     3.7004397181, 1e-6))
    tally(assert( [[36 sqrt]],     6))  -- Square Root
    tally(assert( [[23.1 sqrt]],   4.8062459362, 1e-6))
    tally(assert( [[2 3 **]],      8))  -- Exponentiation
    tally(assert( [[-12 4 **]],    20736))
    tally(assert( [[0 0 **]],      'NaN'))
    tally(assert( [[12 -0.25 **]], 0.5372849659, 1e-6))
    tally(assert( [[10 \]],        0.1))  -- Reciprocal
    tally(assert( [[0 \]],         'Infinity'))

    print('Trigonometry ================================================================')
    tally(assert( [[pi 2 / deg]], 90,           1e-6))  -- convert x to degrees
    tally(assert( [[90 rad]],     1.5707963267, 1e-6))  -- convert x to radians

    tally(assert( [[30 rad sin]], 0.5 ))  -- Sine
    tally(assert( [[60 rad cos]], 0.5 ))  -- Cosine
    tally(assert( [[45 rad tan]], 1.0 ))  -- Tangent
    -- tally(assert( [[90 rad tan]], 'Infinity' ))  -- The actual is VERY large, but not inf.
    tally(assert( [[30 rad csc]], 2.0 ))  -- Cosecant
    tally(assert( [[60 rad sec]], 2.0 ))  -- Secant
    tally(assert( [[45 rad cot]], 1.0 ))  -- Cotangent
    tally(assert( [[0 cot]],      'Infinity' ))  -- Cotangent

    tally(assert( [[0.5 asin deg]], 30 ))  -- Inverse sine
    tally(assert( [[10 asin]],      'NaN' ))
    tally(assert( [[0.5 acos deg]], 60 ))  -- Inverse cosine
    tally(assert( [[-10 acos]],     'NaN' ))
    tally(assert( [[1 atan deg]],   45 ))    -- Inverse Tangent
    tally(assert( [[2.0 acsc deg]], 30 ))  -- Inverse cosecant
    tally(assert( [[0 acsc]],       'NaN' ))  -- Inverse cosecant
    tally(assert( [[2.0 asec deg]], 60 ))  -- Inverse secant
    tally(assert( [[0 asec]],       'NaN' ))  -- Inverse secant
    tally(assert( [[1 acot deg]],   45 ))  -- Inverse cotangent

    tally(assert( [[2 sinh]],             3.6268604078, 1e-6 )) -- Hyperbolic sine
    tally(assert( [[4 cosh]],             27.308232836, 1e-6 )) -- Hyperbolic cosine
    tally(assert( [[-0.5 tanh]],          -0.462117157, 1e-6 )) -- Hyperbolic tangent
    tally(assert( [[3.6268604079 asinh]], 2.0, 1e-6 )) -- Inverse hyperbolic sine
    tally(assert( [[27.30823284 acosh]],  4.0, 1e-6 )) -- Inverse hyperbolic cosine
    tally(assert( [[-0.462117157 atanh]], -0.5, 1e-6 )) -- Inverse hyperbolic tangent
    tally(assert( [[1 atanh]],            'Infinity' ))
    tally(assert( [[-1 atanh]],           '-Infinity' ))
    tally(assert( [[10 atanh]],           'NaN' ))

    tally(assert( [[2 csch]],              0.27572056, 1e-6 ))  -- Hyperbolic cosecant
    tally(assert( [[0 csch]],              'Infinity' ))
    tally(assert( [[-5 sech]],             0.013475282, 1e-6 ))  -- Hyperbolic secant
    tally(assert( [[0 sech]],              1 ))
    tally(assert( [[0.5 coth]],            2.16395341373, 1e-6 ))  -- Hyperbolic cotangent
    tally(assert( [[0 coth]],              'Infinity' ))
    tally(assert( [[0.27572056 acsch]],    2.0, 1e-6 ))  -- Inverse hyperbolic cosecant
    tally(assert( [[0 acsch]],             'Infinity' ))
    tally(assert( [[0.013475282 asech]],   5.0, 1e-6 ))  -- Inverse hyperbolic secant
    tally(assert( [[2.16395341373 acoth]], 0.5, 1e-6 ))  -- Inverse hyperbolic cotangent
    tally(assert( [[0 acoth]],             'NaN' ))

    print('Bitwise =====================================================================')
    tally(assert( [[60 13 &]], 12 ))   -- AND
    tally(assert( [[60 13 |]], 61 ))   -- OR
    tally(assert( [[60 13 ^]], 49 ))   -- XOR
    tally(assert( [[60 ~]],    -61 ))  -- NOT
    tally(assert( [[60 2 <<]], 240 ))  -- Left Shift
    tally(assert( [[60 2 >>]], 15 ))   -- Right Shift

    print('Constants ===================================================================')
    tally(assert( [[pi]],  3.1415926535, 1e-6 ))  -- 3.141592653....
    tally(assert( [[e]],   2.7182818284, 1e-6 ))  -- 2.718281828...
    tally(assert( [[phi]], 1.6180339887, 1e-6 ))  -- golden ratio
    tally(assert( [[i]],   {0,1} ))

    print('Other =======================================================================')
    tally(assert( [[3 20 15 hrs]], 3.3375 ))  -- Convert Z:Y:X to hours
    tally(assert( [[3.3375 hms]], [[3 20 15]] ))  -- Convert X hours to Z:Y:X

    print('AGAIN, BUT WITH COMPLEX NUMBERS ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~')

    print('No Operator (return the input) ==============================================')
    tally(assert( [[12,2]],       {12,2} ))
    tally(assert( [[1,-2 3,4]],  [[1-2i 3+4i]] ))

    print('Basic Arithmetic ============================================================')
    tally(assert( [[3,1  2,6 +]],    {5,7} ))   -- Addtion
    tally(assert( [[3.5  2,6 +]],    {5.5,6} ))
    tally(assert( [[3,1  6 +]],      {9,1} ))
    tally(assert( [[13,4 2,2 -]],    {11,2} ))  -- Subtraction
    tally(assert( [[13   2,2 -]],    {11,-2} ))
    tally(assert( [[13,4 2 -]],      {11,4} ))
    tally(assert( [[1,4  3,2 *]],    {-5,14} ))  -- Multiplication
    tally(assert( [[4    3,2 *]],    {12,8} ))
    tally(assert( [[1,4  3 *]],      {3,12} ))
    tally(assert( [[2,4  2 /]],      {1,2} ))   -- Division
    tally(assert( [[2    4,2 /]],    {0.4,-0.2} ))
    tally(assert( [[3,-1 4,2 /]],    {0.5,-0.5} ))

    tally(assert( [[3,4 abs]],     5 ))   -- Absolute Value

    tally(assert( [[1,1 arg]],     0.78539816339745, 1e-6 ))  -- Arg
    tally(assert( [[-3,1 arg]],     2.8198420991932, 1e-6 ))
    tally(assert( [[-3,-2 arg]],     -2.5535900500422, 1e-6 ))
    tally(assert( [[2,-1 arg]],     -0.46364760900081, 1e-6 ))

    tally(assert( [[-8,2 chs]],    {8,-2} ))   -- Change Sign

    print('Rounding ====================================================================')
    tally(assert( [[12.3,4.2 floor]],   {12,4} ))  -- Floor - round down to nearest integer
    tally(assert( [[-12.3,-4.2 floor]], {-13,-5} ))
    tally(assert( [[12.3,4.2 ceil]],    {13,5} ))  -- Ceiling - round up to nearest integer
    tally(assert( [[-12.3,-4.2 ceil]],  {-12,-4} ))
    tally(assert( [[12.3,4.7 round]],   {12,5} ))  -- Round to nearest integer
    tally(assert( [[-12.3,-4.7 round]], {-12,-5} ))
    tally(assert( [[12.7,4.3 round]],   {13,4} ))
    tally(assert( [[-12.7,-4.3 round]], {-13,-4} ))
    tally(assert( [[12.7,4.3 trunc]],   {12,4} ))  -- Round toward zero
    tally(assert( [[-12.7,-4.3 trunc]], {-12,-4} ))

    print('Powers & Logs ===============================================================')
    tally(assert( [[2,1 exp]],      {3.992324048,6.217676312}, 1e-6 )) -- Raise e to the x power
    tally(assert( [[2,3 ln]],      {1.282474678,0.982793723}, 1e-6 ))  -- Natural log of x
    tally(assert( [[2,3 log]],    {0.556971676,0.426821891}, 1e-6 ))  -- Log (base 10) of x
    tally(assert( [[2,3 log2]],     {1.850219859,1.417871631}, 1e-6 ))  -- Log (base 2) of x
    tally(assert( [[2,3 1,2 logx]], {1.131731655,-0.335771298}, 1e-6 ))  -- Log (base x) of y
    tally(assert( [[-4 sqrt]],      {0,2}, 1e-6))  -- Square root
    tally(assert( [[2,3.1 sqrt]],   {1.6865902,0.91901396}, 1e-6 ))
    tally(assert( [[0,1 2 **]],     {-1,0}, 1e-6 ))  -- Exponentiation
    tally(assert( [[0,1 3 **]],     {0,-1}, 1e-6 ))
    tally(assert( [[1,1 2 **]],     {0,2}, 1e-6 ))
    tally(assert( [[3 1,-2 **]],    {-1.7587648,-2.4303798}, 1e-6))
    tally(assert( [[-4,3 1,-2 **]], {555.3814991,-487.8784553}, 1e-6))
    tally(assert( [[-7 3.3 **]],    {-361.4449966, -497.4863586}, 1e-6))
    tally(assert( [[0,0 0 **]],     'NaN' ))
    tally(assert( [[0 0,0 **]],     'NaN' ))
    tally(assert( [[0,0 0,0 **]],   'NaN' ))
    tally(assert( [[0,0 \]],        'NaN' ))
    tally(assert( [[2,3 \]],        {2/13, -3/13}, 1e-6))

    print('Trigonometry ================================================================')
    tally(assert( [[1,1 sin]], {1.298457581,0.634963915}, 1e-6))
    tally(assert( [[1,1 cos]], {0.833730025,-0.988897706}, 1e-6))
    tally(assert( [[1,1 tan]], {0.271752585,1.083923327}, 1e-6))
    tally(assert( [[1,1 csc]], {0.621518017,-0.303931002}, 1e-6))
    tally(assert( [[1,1 sec]], {0.498337031,0.591083842}, 1e-6))
    tally(assert( [[1,1 cot]], {0.217621562,-0.868014143}, 1e-6))

    tally(assert( [[1,2 sinh]], {-0.489056259,1.403119251}, 1e-6))
    tally(assert( [[1,2 cosh]], {-0.642148716,1.068607421}, 1e-6))
    tally(assert( [[1,2 tanh]], {1.166736257,-0.243458201}, 1e-6))
    tally(assert( [[1,2 csch]], {-0.221500931,-0.635493799}, 1e-6))
    tally(assert( [[1,2 sech]], {-0.413149344,-0.687527439}, 1e-6))
    tally(assert( [[1,2 coth]], {0.821329797,0.171383613}, 1e-6))

    tally(assert( [[1,1 asin]], {0.666239432,1.061275062}, 1e-6))
    tally(assert( [[1,1 acos]], {0.904556894,-1.061275062}, 1e-6))
    tally(assert( [[1,1 atan]], {1.017221968,0.402359478}, 1e-6))
    tally(assert( [[1,1 acsc]], {0.452278447,-0.530637531}, 1e-6))
    tally(assert( [[1,1 asec]], {1.118517880,0.530637531}, 1e-6))
    tally(assert( [[1,1 acot]], {0.553574359,-0.402359478}, 1e-6))

    tally(assert( [[1,1 asinh]], {1.061275062,0.666239432}, 1e-6))
    tally(assert( [[1,1 acosh]], {1.061275062,0.904556894}, 1e-6))
    tally(assert( [[1,1 atanh]], {0.402359478,1.017221968}, 1e-6))
    tally(assert( [[1,1 acsch]], {0.530637531,-0.452278447}, 1e-6))
    tally(assert( [[1,1 asech]], {0.530637531,-1.118517880}, 1e-6))
    tally(assert( [[1,1 acoth]], {0.402359478,-0.553574359}, 1e-6))

    print('Bases (Reading & Writing) ================================================================')
    tally(assert( [[0x22]], 34))
    tally(assert( [[0b100011]], 35))
    tally(assert( [[150 hex]], '0x96'))
    tally(assert( [[150 bin]], '0b10010110'))
    tally(assert( [[hex 150]], '0x96'))
    tally(assert( [[bin 150]], '0b10010110'))
    tally(assert( [[bin 20.1234]], '0b10100'))
    tally(assert( [[bin 20.1234,42.8352]], '0b10100+0b101010i'))
    tally(assert( [[-150 hex]], '-0x96'))
    tally(assert( [[-150 bin]], '-0b10010110'))


    -- All done. Print the final tally.
    print(string.format('\n%4d test(s) passed.  %4d test(s) failed.', passedTests, failedTests)) end
return M
