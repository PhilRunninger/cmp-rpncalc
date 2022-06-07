# cmp-rpncalc
nvim-cmp source for math calculations using Reverse Polish Notation

## How Does RPN Work?

RPN is a way of writing a mathematical expression where the operator follows the operand(s) it uses. This means there's no need for parentheses.

## Operands

Operands include numbers in any of the following formats:

Regex (Vim format) | Example | Description
---|---
`\v[+-]?\d+\.?\d*(e[+-]?\d+)?` | Decimal, Scientific Notation
`\v[+-]?0b[01]+` | Binary
`\v[+-]?0o[0-7]+` | Octal
`\v\c[+-]?0x[0-9a-f]+` | Hexadecimal
`\v[+-]?\d+\.?\d*(e[+-]?\d+)?[+-]\d+\.?\d*(e[+-]?\d+)?i` | Complex

## Operators
### Arithmetic
+    => 'Addition',
*    => 'Multiplication',
-    => 'Subtraction',
/    => 'Division',
div  => 'Integer division',
%    => 'Modulus',
**   => 'Exponentiation',
abs  => 'Absolute value',
chs  => 'Negation',
### Rounding
'round'    => 'Round to nearest integer',
'truncate' => 'Truncate to integer',
'floor'    => 'Round down to nearest integer',
'ceil'     => 'Round up to nearest integer',
### Powers & Logs
'exp'   => 'Raise e to the x power',
'log'   => 'Natural Log of x',
'log10' => 'Log (base 10) of x',
'log2'  => 'Log (base 2) of x',
'sqrt'  => 'Square Root',
'\\'    => 'Reciprocal',
### Trigonometry
'sin'   => 'Sine of x',
'asin'  => 'Arcsine of x',
'cos'   => 'Cosine of x',
'acos'  => 'Arccosine of x',
'tan'   => 'Tangent of x',
'atan'  => 'Artangent of x',
### Statistics
'!'       => 'Factorial',
'perm'    => 'Permutation(Y, X)',
'comb'    => 'Combination(Y, X)',
'sum'     => 'Sum of stack',
'product' => 'Product of stack',
'mean'    => 'Mean average',
'median'  => 'Median average',
'std'     => 'Standard Deviation',
'count'   => 'Size of stack',
### Bitwise
'&'  => 'AND',
'|'  => 'OR',
'^'  => 'XOR',
'<<' => 'Left Shift',
'>>' => 'Right Shift',
'~'  => "1's complement",
### Constants
'pi'  => '3.141592653....',
'e'   => '2.718281828...',
'phi' => '0.618033989...',
'i' => 'sqrt(-1)',
### Stack
'copy' => 'Copy top value on stack',
'del'  => 'Delete top value from stack',
'xy'   => 'Swap x and y',
### Display Mode
'bin'  => 'Binary: 0b[01]+',
'oct'  => 'Octal: 0[0-7]+',
'hex'  => 'Hexadecimal: 0x[0-9a-f]+',
'dec'  => 'Decimal (integer)',
'norm' => 'Normal mode',
### Angle Mode
'rad' => 'Switch to radians',
'deg' => 'Switch to degrees',
### Other
'hrs' => 'Convert Z:Y:X to hours',
'hms' => 'Convert X hours to Z:Y:X',
    ]
