-- vim: foldmethod=marker
--
-- To run the tests, use these commands:
--
-- :wa|mess clear|lua require('cmp_rpncalc.tests').rerun(false)
--          - false prints only failure messages
--          - true prints all messages
-- :messages

M = {}

local printAll = false
local rpn = require('cmp_rpncalc.rpn')

local function mockRequest(str)  -- {{{1
    return { context = { cursor_before_line = str, cursor = { row = 1, col = 1 } } }
end

local function equalArrays(actual, expected, tolerance)
    -- vim.print('Actual:', actual, '  Expected:', expected)
    if #actual ~= #expected then
        return false end
    for i = 1, #actual do
        -- vim.print('Actual['.. i.. ']:', actual[i], '  Expected['.. i.. ']:', expected[i])
        if type(actual[i]) ~= type(expected[i]) then return false end
        if type(actual[i]) == 'table' and not equalArrays(actual[i], expected[i], tolerance) then return false end
        if type(actual[i]) ~= 'table' and tolerance and math.abs(actual[i] - expected[i]) > tolerance then return false end
        if type(actual[i]) ~= 'table' and not tolerance and actual[i] ~= expected[i] then return false end
    end
    return true
end

local function assertOperator(stack, operators, expected, tolerance)  -- {{{1
    local msg = vim.fn.join(stack, ' ') .. ' ' .. (type(operators) == 'table' and vim.fn.join(operators, ' ') or operators)
    msg = string.format('  Input: %30s  Expected: %s', msg, vim.fn.join(expected, ' '))
    msg = msg .. (tolerance
        and string.format(' ± %-15s', tolerance)
        or  '')
    local pass = true

    rpn.init()
    rpn.stack = stack

    if type(operators) == 'table' then
        for _,operator in ipairs(operators) do
            local f = rpn.op[operator]
            local ok,_ = pcall(f)
            pass = pass and ok
        end
    else
        local f = rpn.op[operators]
        local ok,_ = pcall(f)
        pass = ok
    end
    pass = pass and equalArrays(rpn.stack, expected, tolerance)

    msg = msg .. (pass and '' or '  Got: ' .. vim.fn.join(rpn.stack, ' '))
    if printAll or not pass then
        print(pass and '    pass' or '    FAIL', msg)
    end
    return pass
end

local function assertCMP(expression, expected, tolerance)  -- {{{1
    local msg = type(expected) == 'table'
        and string.format('    %25s  should equal {%s, %s} ', expression, expected[1], expected[2])
        or string.format('    %25s  should equal  %s ', expression, expected)
    msg = msg .. (tolerance
        and string.format('± %-15s', tolerance)
        or  '')
    local pass = false
    local checkResult = function(response)
        -- vim.print('response', response)
        local result = ''
        if next(response) == nil then
            result = ''
            pass = false
        else
            result = response.items[2].textEdit.newText
            if type(expected) == 'string' then
                pass = vim.regex([[^]]..expected..[[$]]):match_str(result) and true or false
            else
                tolerance = tolerance or 0
                if type(expected) == 'table' then
                    -- Split complex result into real and imaginary: "1.23+4.5i" -> {"1.23", "+4.5"}
                    local parts = vim.fn.split(result, '\\(\\ze[+-]\\|i\\)')
                    -- vim.print(parts)
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
                    -- vim.print(parts, expected)

                    pass = #parts == #expected and
                        math.abs(tonumber(parts[1])-expected[1]) <= tolerance and
                        math.abs(tonumber(parts[2])-expected[2]) <= tolerance
                elseif tonumber(expected) and tonumber(result) then
                    pass = math.abs(tonumber(result)-expected) <= tolerance
                else
                    pass = false
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

function M.rerun(verbose)  -- {{{1
    -- Rerun the tests after reloading (and recompiling) the source and test code.
    vim.schedule(function()
        package.loaded['cmp_rpncalc'] = nil
        package.loaded['cmp_rpncalc.tests'] = nil
        require('cmp_rpncalc.tests').run(verbose)
    end)
end

function M.run(verbose) -- Unit Tests {{{1
    printAll = verbose and true or false
    local passedTests = 0
    local failedTests = 0

    local tally = function(pass)
        passedTests = passedTests + (pass and 1 or 0)
        failedTests = failedTests + (pass and 0 or 1)
    end

    -- Test RPN functions.
    print('Testing RPN Operators #######################################################')
    print('Basic Arithmetic ============================================================')
    tally(assertOperator( {3, 2}, '+',     {5}))   -- Addtion
    tally(assertOperator( {3.1, 2.2}, '+', {5.3}, 1e-12))
    tally(assertOperator( {13, 2}, '-',    {11}))  -- Subtraction
    tally(assertOperator( {1.3, 2}, '-',   {-0.7}))
    tally(assertOperator( {14, 3}, '*',    {42}))  -- Multiplication
    tally(assertOperator( {1.4, .3}, '*',  {0.42}))
    tally(assertOperator( {24, 8}, '/',    {3}))   -- Division
    tally(assertOperator( {8, 24}, '/',    {0.333333333333}, 1e-6))
    tally(assertOperator( {23, 5}, 'div',  {4}))   -- Integer part of division
    tally(assertOperator( {-23, 5}, 'div', {-4}))
    tally(assertOperator( {23, 5}, '%',    {3}))   -- Remainder of division
    tally(assertOperator( {23, -5}, '%',   {-2}))
    tally(assertOperator( {-23, 5}, '%',   {2}))
    tally(assertOperator( {-23, -5}, '%',  {-3}))
    tally(assertOperator( {7}, 'abs',     {7}))   -- Absolute Value
    tally(assertOperator( {-7}, 'abs',    {7}))
    tally(assertOperator( {1}, 'arg',     {0 }))  -- Arg
    tally(assertOperator( {0}, 'arg',     {0 }))
    tally(assertOperator( {-1}, 'arg',    {math.pi}, 1e-6 ))
    tally(assertOperator( {-8}, 'chs',    {8}))   -- Change Sign
    tally(assertOperator( {8}, 'chs',     {-8}))

    print('Rounding ====================================================================')
    tally(assertOperator( {12.3}, 'floor',  {12 }))  -- Floor - round down to nearest integer
    tally(assertOperator( {-12.3}, 'floor', {-13 }))
    tally(assertOperator( {12.3}, 'ceil',   {13 }))  -- Ceiling - round up to nearest integer
    tally(assertOperator( {-12.3}, 'ceil',  {-12 }))
    tally(assertOperator( {12.3}, 'round',  {12 }))  -- Round to nearest integer
    tally(assertOperator( {-12.3}, 'round', {-12 }))
    tally(assertOperator( {12.7}, 'round',  {13 }))
    tally(assertOperator( {-12.7}, 'round', {-13 }))
    tally(assertOperator( {12.7}, 'trunc',  {12 }))  -- Round toward zero
    tally(assertOperator( {-12.7}, 'trunc', {-12 }))

    print('Powers & Logs ===============================================================')
    tally(assertOperator( {2}, 'exp',       {7.3890560989}, 1e-6))  -- Raise e to the x power
    tally(assertOperator( {0}, 'exp',       {1}))
    tally(assertOperator( {0.1}, 'exp',     {1.1051709180}, 1e-6))
    tally(assertOperator( {120}, 'ln',     {4.7874917427}, 1e-6))  -- Natural log of x
    tally(assertOperator( {625, 5}, 'logx',  {4}))  -- Log (base x) of y
    tally(assertOperator( {1000}, 'log',  {3}, 1e-12))  -- Log (base 10) of x
    tally(assertOperator( {12345}, 'log', {4.0914910942}, 1e-6))
    tally(assertOperator( {1024}, 'log2',   {10}))  -- Log (base 2) of x
    tally(assertOperator( {13}, 'log2',     {3.7004397181}, 1e-6))
    tally(assertOperator( {36}, 'sqrt',     {6}))  -- Square Root
    tally(assertOperator( {23.1}, 'sqrt',   {4.8062459362}, 1e-6))
    tally(assertOperator( {2, 3}, '**',      {8}))  -- Exponentiation
    tally(assertOperator( {-12, 4}, '**',    {20736}))
    tally(assertOperator( {12, -0.25}, '**', {0.5372849659}, 1e-6))
    tally(assertOperator( {10}, '\\',        {0.1}))  -- Reciprocal

    print('Trigonometry ================================================================')

    tally(assertOperator( {math.pi, 2}, {'/', 'deg'}, {90}, 1e-6))  -- convert x to degrees
    tally(assertOperator( {90}, 'rad',     {1.5707963267}, 1e-6))  -- convert x to radians

    tally(assertOperator( {math.pi, 6}, {'/', 'sin'}, {0.5}, 1e-6 ))  -- Sine
    tally(assertOperator( {math.pi, 3}, {'/', 'cos'}, {0.5}, 1e-6 ))  -- Cosine
    tally(assertOperator( {math.pi, 4}, {'/', 'tan'}, {1.0}, 1e-6 ))  -- Tangent
    -- tally(assert( {90, rad}, 'tan', 'Infinity' ))  -- The actual is VERY large, but not inf.
    tally(assertOperator( {math.pi, 6}, {'/', 'csc'}, {2.0}, 1e-6 ))  -- Cosecant
    tally(assertOperator( {math.pi, 3}, {'/', 'sec'}, {2.0}, 1e-6 ))  -- Secant
    tally(assertOperator( {math.pi, 4}, {'/', 'cot'}, {1.0}, 1e-6 ))  -- Cotangent

    tally(assertOperator( {0.5}, 'asin', {0.523598776}, 1e-6 ))  -- Inverse sine
    tally(assertOperator( {0.5}, 'acos', {1.047197551}, 1e-6 ))  -- Inverse cosine
    tally(assertOperator( {1}, 'atan',   {0.785398163}, 1e-6 ))    -- Inverse Tangent
    tally(assertOperator( {2.0}, 'acsc', {0.523598776}, 1e-6 ))  -- Inverse cosecant
    tally(assertOperator( {2.0}, 'asec', {1.047197551}, 1e-6 ))  -- Inverse secant
    tally(assertOperator( {1}, 'acot',   {0.785398163}, 1e-6 ))  -- Inverse cotangent

    tally(assertOperator( {2}, 'sinh',             {3.6268604078}, 1e-6 )) -- Hyperbolic sine
    tally(assertOperator( {4}, 'cosh',             {27.308232836}, 1e-6 )) -- Hyperbolic cosine
    tally(assertOperator( {-0.5}, 'tanh',          {-0.462117157}, 1e-6 )) -- Hyperbolic tangent
    tally(assertOperator( {3.6268604079}, 'asinh', {2.0}, 1e-6 )) -- Inverse hyperbolic sine
    tally(assertOperator( {27.30823284}, 'acosh',  {4.0}, 1e-6 )) -- Inverse hyperbolic cosine
    tally(assertOperator( {-0.462117157}, 'atanh', {-0.5}, 1e-6 )) -- Inverse hyperbolic tangent

    tally(assertOperator( {2}, 'csch',              {0.27572056}, 1e-6 ))  -- Hyperbolic cosecant
    tally(assertOperator( {-5}, 'sech',             {0.013475282}, 1e-6 ))  -- Hyperbolic secant
    tally(assertOperator( {0}, 'sech',              {1} ))
    tally(assertOperator( {0.5}, 'coth',            {2.16395341373}, 1e-6 ))  -- Hyperbolic cotangent
    tally(assertOperator( {0.27572056}, 'acsch',    {2.0}, 1e-6 ))  -- Inverse hyperbolic cosecant
    tally(assertOperator( {0.013475282}, 'asech',   {5.0}, 1e-6 ))  -- Inverse hyperbolic secant
    tally(assertOperator( {2.16395341373}, 'acoth', {0.5}, 1e-6 ))  -- Inverse hyperbolic cotangent

    print('Bitwise =====================================================================')
    tally(assertOperator( {60, 13}, '&', {12} ))   -- AND
    tally(assertOperator( {60, 13}, '|', {61} ))   -- OR
    tally(assertOperator( {60, 13}, '^', {49} ))   -- XOR
    tally(assertOperator( {60}, '~',    {-61} ))  -- NOT
    tally(assertOperator( {60, 2}, '<<', {240} ))  -- Left Shift
    tally(assertOperator( {60, 2}, '>>', {15} ))   -- Right Shift

    print('Other =======================================================================')
    tally(assertOperator( {3, 20, 15}, 'hrs', {3.3375} ))      -- Convert Z:Y:X to hours
    tally(assertOperator( {3.3375}, 'hms', {3, 20, 15}, 1e-12 ))  -- Convert X hours to Z:Y:X
    tally(assertOperator( {12, 15}, 'gcd', {3} ))         -- Greatest Common Divisor
    tally(assertOperator( {12, 30, 48}, {'gcd', 'gcd'}, {6} ))
    tally(assertOperator( {-12, 15}, 'gcd', {3} ))
    tally(assertOperator( {2, -5}, 'gcd', {1} ))
    tally(assertOperator( {0, 0}, 'gcd', {0} ))
    tally(assertOperator( {0, 42}, 'gcd', {42} ))
    tally(assertOperator( {12, 15}, 'lcm', {60} ))        -- Least Common Multiple
    tally(assertOperator( {2, 3, 4, 5, 7}, {'lcm', 'lcm', 'lcm', 'lcm'}, {420} ))
    tally(assertOperator( {-12, 15}, 'lcm', {60} ))
    tally(assertOperator( {2, -5}, 'lcm', {10} ))
    tally(assertOperator( {2, 0}, 'lcm', {0} ))
    tally(assertOperator( {0, 0}, 'lcm', {0} ))

    print('Complex: Basic Arithmetic ===================================================')
    tally(assertOperator( {{3,1}, {2,6}}, '+',    {{5,7}} ))   -- Addtion
    tally(assertOperator( {3.5, {2,6}}, '+',    {{5.5,6}} ))
    tally(assertOperator( {{3,1}, 6}, '+',      {{9,1}} ))
    tally(assertOperator( {{13,4}, {2,2}}, '-',    {{11,2}} ))  -- Subtraction
    tally(assertOperator( {13, {2,2}}, '-',    {{11,-2}} ))
    tally(assertOperator( {{13,4}, 2}, '-',      {{11,4}} ))
    tally(assertOperator( {{1,4}, {3,2}}, '*',    {{-5,14}} ))  -- Multiplication
    tally(assertOperator( {4, {3,2}}, '*',    {{12,8}} ))
    tally(assertOperator( {{1,4}, 3}, '*',      {{3,12}} ))
    tally(assertOperator( {{2,4}, 2}, '/',      {{1,2}} ))   -- Division
    tally(assertOperator( {2, {4,2}}, '/',    {{0.4,-0.2}} ))
    tally(assertOperator( {{3,-1}, {4,2}}, '/',    {{0.5,-0.5}} ))

    tally(assertOperator( {{3,4}}, 'abs',     {5} ))   -- Absolute Value

    tally(assertOperator( {{1,1}}, 'arg',     {0.78539816339745}, 1e-6 ))  -- Arg
    tally(assertOperator( {{-3,1}}, 'arg',     {2.8198420991932}, 1e-6 ))
    tally(assertOperator( {{-3,-2}}, 'arg',     {-2.5535900500422}, 1e-6 ))
    tally(assertOperator( {{2,-1}}, 'arg',     {-0.46364760900081}, 1e-6 ))

    tally(assertOperator( {{-8,2}}, 'chs',    {{8,-2}} ))   -- Change Sign

    print('Complex: Rounding ===========================================================')
    tally(assertOperator( {{12.3,4.2}}, 'floor',   {{12,4}} ))  -- Floor - round down to nearest integer
    tally(assertOperator( {{-12.3,-4.2}}, 'floor', {{-13,-5}} ))
    tally(assertOperator( {{12.3,4.2}}, 'ceil',    {{13,5}} ))  -- Ceiling - round up to nearest integer
    tally(assertOperator( {{-12.3,-4.2}}, 'ceil',  {{-12,-4}} ))
    tally(assertOperator( {{12.3,4.7}}, 'round',   {{12,5}} ))  -- Round to nearest integer
    tally(assertOperator( {{-12.3,-4.7}}, 'round', {{-12,-5}} ))
    tally(assertOperator( {{12.7,4.3}}, 'round',   {{13,4}} ))
    tally(assertOperator( {{-12.7,-4.3}}, 'round', {{-13,-4}} ))
    tally(assertOperator( {{12.7,4.3}}, 'trunc',   {{12,4}} ))  -- Round toward zero
    tally(assertOperator( {{-12.7,-4.3}}, 'trunc', {{-12,-4}} ))

    print('Complex: Powers & Logs ======================================================')
    tally(assertOperator( {{2,1}}, 'exp',      {{3.992324048,6.217676312}}, 1e-6 )) -- Raise e to the x power
    tally(assertOperator( {{2,3}}, 'ln',      {{1.282474678,0.982793723}}, 1e-6 ))  -- Natural log of x
    tally(assertOperator( {{2,3}}, 'log',    {{0.556971676,0.426821891}}, 1e-6 ))  -- Log (base 10) of x
    tally(assertOperator( {{2,3}}, 'log2',     {{1.850219859,1.417871631}}, 1e-6 ))  -- Log (base 2) of x
    tally(assertOperator( {{2,3}, {1,2}}, 'logx', {{1.131731655,-0.335771298}}, 1e-6 ))  -- Log (base x) of y
    tally(assertOperator( {-4}, 'sqrt',      {{0,2}}, 1e-6))  -- Square root
    tally(assertOperator( {{2,3.1}}, 'sqrt',   {{1.6865902,0.91901396}}, 1e-6 ))
    tally(assertOperator( {{0,1}, 2}, '**',     {{-1,0}}, 1e-6 ))  -- Exponentiation
    tally(assertOperator( {{0,1}, 3}, '**',     {{0,-1}}, 1e-6 ))
    tally(assertOperator( {{1,1}, 2}, '**',     {{0,2}}, 1e-6 ))
    tally(assertOperator( {3, {1,-2}}, '**',    {{-1.7587648,-2.4303798}}, 1e-6))
    tally(assertOperator( {{-4,3}, {1,-2}}, '**', {{555.3814991,-487.8784553}}, 1e-6))
    tally(assertOperator( {-7, 3.3}, '**',    {{-361.4449966, -497.4863586}}, 1e-6))
    tally(assertOperator( {{2,3}}, '\\',        {{2/13, -3/13}}, 1e-6))

    print('Complex: Trigonometry =======================================================')
    tally(assertOperator( {{1,1}}, 'sin', {{1.298457581,0.634963915}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'cos', {{0.833730025,-0.988897706}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'tan', {{0.271752585,1.083923327}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'csc', {{0.621518017,-0.303931002}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'sec', {{0.498337031,0.591083842}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'cot', {{0.217621562,-0.868014143}}, 1e-6))

    tally(assertOperator( {{1,2}}, 'sinh', {{-0.489056259,1.403119251}}, 1e-6))
    tally(assertOperator( {{1,2}}, 'cosh', {{-0.642148716,1.068607421}}, 1e-6))
    tally(assertOperator( {{1,2}}, 'tanh', {{1.166736257,-0.243458201}}, 1e-6))
    tally(assertOperator( {{1,2}}, 'csch', {{-0.221500931,-0.635493799}}, 1e-6))
    tally(assertOperator( {{1,2}}, 'sech', {{-0.413149344,-0.687527439}}, 1e-6))
    tally(assertOperator( {{1,2}}, 'coth', {{0.821329797,0.171383613}}, 1e-6))

    tally(assertOperator( {{1,1}}, 'asin', {{0.666239432,1.061275062}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acos', {{0.904556894,-1.061275062}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'atan', {{1.017221968,0.402359478}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acsc', {{0.452278447,-0.530637531}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'asec', {{1.118517880,0.530637531}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acot', {{0.553574359,-0.402359478}}, 1e-6))

    tally(assertOperator( {{1,1}}, 'asinh', {{1.061275062,0.666239432}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acosh', {{1.061275062,0.904556894}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'atanh', {{0.402359478,1.017221968}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acsch', {{0.530637531,-0.452278447}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'asech', {{0.530637531,-1.118517880}}, 1e-6))
    tally(assertOperator( {{1,1}}, 'acoth', {{0.402359478,-0.553574359}}, 1e-6))

    print('Statistics ==================================================================')
    tally(assertOperator( {6}, '!', {720}))
    tally(assertOperator( {0}, '!', {1}))
    tally(assertOperator( {5, 3}, 'perm', {60}))
    tally(assertOperator( {5, 3}, 'comb', {10}))
    tally(assertOperator( {2, 5, 7, 11}, 'mean', {6.25}))
    tally(assertOperator( {{2,1}, {5,2}, 7, {1,1}}, 'mean', {{3.75,1}}))
    tally(assertOperator( {2, 5, 7, 11}, 'std', {3.774917218}, 1e-6))
    tally(assertOperator( {2, 5, 7, 11}, 'n', {4}))
    tally(assertOperator( {}, 'n', {0}))
    tally(assertOperator( {2, 5, 7, 11}, 'sum', {25}))
    tally(assertOperator( {{2,1}, {5,2}, 7, {1,1}}, 'sum', {{15,4}}))
    tally(assertOperator( {2, 5, 7, 11}, 'ssq', {199}))
    tally(assertOperator( {{2,1}, {5,2}, 7, {1,1}}, 'ssq', {{73,26}}))


    print('Testing Returned Text #######################################################')
    print('No Operator (return the input) ==============================================')
    tally(assertCMP( [[12]],       [[12]] ))
    tally(assertCMP( [[1 2 3 4]],  [[1 2 3 4]] ))
    tally(assertCMP( [[12,2]],       [[12+2i]] ))
    tally(assertCMP( [[1,-2 3,4]],  [[1-2i 3+4i]] ))

    print('Handle Invalid Operations ===================================================')
    tally(assertCMP( [[7 0 /]],        'Infinity'))
    tally(assertCMP( [[0 0 /]],        'NaN'))
    tally(assertCMP( [[0 ln]],         '-Infinity'))
    tally(assertCMP( [[625 -5 logx]],  'NaN'))
    tally(assertCMP( [[-625 5 logx]],  'NaN'))
    tally(assertCMP( [[0 0 **]],       'NaN'))
    tally(assertCMP( [[0 \]],          'Infinity'))
    tally(assertCMP( [[0 cot]],        'Infinity' ))
    tally(assertCMP( [[10 asin]],      'NaN' ))
    tally(assertCMP( [[-10 acos]],     'NaN' ))
    tally(assertCMP( [[0 acsc]],       'NaN' ))
    tally(assertCMP( [[0 asec]],       'NaN' ))
    tally(assertCMP( [[1 atanh]],      'Infinity' ))
    tally(assertCMP( [[-1 atanh]],     '-Infinity' ))
    tally(assertCMP( [[10 atanh]],     'NaN' ))
    tally(assertCMP( [[0 csch]],       'Infinity' ))
    tally(assertCMP( [[0 coth]],       'Infinity' ))
    tally(assertCMP( [[0 acsch]],      'Infinity' ))
    tally(assertCMP( [[0 acoth]],      'NaN' ))
    tally(assertCMP( [[1,2 30 gcd]],   'NaN' ))
    tally(assertCMP( [[1.2 3.4 gcd]],  'NaN' ))
    tally(assertCMP( [[1,2 30 lcm]],   'NaN' ))
    tally(assertCMP( [[1.2 3.4 lcm]],  'NaN' ))
    tally(assertCMP( [[0,0 0 **]],     'NaN' ))
    tally(assertCMP( [[0 0,0 **]],     'NaN' ))
    tally(assertCMP( [[0,0 0,0 **]],   'NaN' ))
    tally(assertCMP( [[0,0 \]],        'NaN' ))
    tally(assertCMP( [[3.14 !]],       'NaN'))
    tally(assertCMP( [[-5 !]],         'NaN'))
    tally(assertCMP( [[2,5 !]],        'NaN'))
    tally(assertCMP( [[2,5 7 11 std]], 'NaN'))

    print('Constants ===================================================================')
    tally(assertCMP( [[pi]],  3.1415926535, 1e-6 ))  -- 3.141592653....
    tally(assertCMP( [[e]],   2.7182818284, 1e-6 ))  -- 2.718281828...
    tally(assertCMP( [[phi]], 1.6180339887, 1e-6 ))  -- golden ratio
    tally(assertCMP( [[i]],   '0+1i' ))

    print('Bases (Reading & Writing) ===================================================')
    tally(assertCMP( [[0x22]], 34))
    tally(assertCMP( [[0b100011]], 35))
    tally(assertCMP( [[-0x22]], -34))
    tally(assertCMP( [[-0b100011]], -35))
    tally(assertCMP( [[150 hex]], '0x96'))
    tally(assertCMP( [[150 bin]], '0b10010110'))
    tally(assertCMP( [[0x37 dec]], 55))
    tally(assertCMP( [[hex 150]], '0x96'))
    tally(assertCMP( [[bin 150]], '0b10010110'))
    tally(assertCMP( [[dec 0x37]], 55))
    tally(assertCMP( [[bin 20.1234]], '0b10100'))
    tally(assertCMP( [[bin 20.1234,42.8352]], '0b10100+0b101010i'))
    tally(assertCMP( [[-150 hex]], '-0x96'))
    tally(assertCMP( [[-150 bin]], '-0b10010110'))
    tally(assertCMP( [[-0x37 dec]], -55))

    print('Memory and Stack Manipulation ===============================================')
    -- sto cannot be tested by itself, as it doesn't change the output.
    tally(assertCMP( [[1 sto rcl]], '1 1'))
    tally(assertCMP( [[1 sto m+ rcl]], '1 2'))
    tally(assertCMP( [[1 sto 3 m- rcl]], '1 3 -2'))
    tally(assertCMP( [[1 2 xy]], '2 1'))
    tally(assertCMP( [[rcl]], ''))  -- Don't fail if memory is not set.
    tally(assertCMP( [[sto rcl]], ''))  -- Don't fail if stack is empty.
    tally(assertCMP( [[1 x]], '1 1'))
    tally(assertCMP( [[1 2 + x]], '3 2'))
    tally(assertCMP( [[1,2 x]], '1+2i 1+2i'))
    tally(assertCMP( [[i x]], '0+1i 0+1i'))
    tally(assertCMP( [[x]], ''))  -- Don't fail if stack is empty.
    tally(assertCMP( [[1 drop]], ''))
    tally(assertCMP( [[1 2 drop]], 1))
    tally(assertCMP( [[drop]], ''))  -- Don't fail if stack is empty.


    -- All done. Print the final tally.
    print(string.format('\nDone.\n%4d test(s) passed.  %4d test(s) failed.', passedTests, failedTests)) end
return M
