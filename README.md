# cmp-rpncalc
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for math calculations using Reverse Polish Notation

## Installation

Use your favorite plugin manager to install this plugin. [vim-pathogen](https://github.com/tpope/vim-pathogen), [vim-plug](https://github.com/junegunn/vim-plug), and [Packer.nvim](https://github.com/wbthomason/packer.nvim) are some of the more popular ones. A lengthy discussion of these and other managers can be found on [vi.stackexchange.com](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).

If you have no favorite, or want to manage your plugins without 3rd-party dependencies, use packages, as described in Greg Hurrell's excellent Youtube video: [Vim screencast #75: Plugin managers](https://www.youtube.com/watch?v=X2_R3uxDN6g)

## Setup
There is no setup required specifically for this plugin; however, you need to add **rpncalc** to the list of sources in your **nvim-cmp** setup. The following snippet shows how to do that.
```
require'cmp'.setup {
  sources = {
    { name = 'rpncalc' }
  }
}
```

## How Does RPN Work?

RPN is a mathematical notation in which the operator follows its operand(s). This means there is no need for parentheses. Here are some examples:
* Add **956** and **37**: `956 37 +`
* Divide **452** by **12** (Remember, the order of operands is important.): `452 12 /`
* Find the **arctangent** of **1/√3**: `3 sqrt \ atan deg`
* Evaluate **3x²+13x-10** at **x=4**: `3 4 2 ** * 13 4 * + 10 -`

Reading an expression from left to right, numbers are placed on a stack. The top four numbers are labeled `X`, `Y`, `Z`, and `T` from the top down. Although these labels are not shown when using the plugin, they are referenced in the README and the documentation. When an operator is encountered, one or more numbers (as needed by the operator) are popped from the stack, and the result of the operation is pushed back on the stack.

## Complex Numbers
Most of the operators also will process complex numbers. The following Wikipedia pages were used as reference for some of the more arcane derivations for complex numbers. Where the complete answer is an infinte number of answers, only the principal value is given.
* [logarithms](https://en.wikipedia.org/wiki/Complex_logarithm)
* [exponentiation](https://en.wikipedia.org/wiki/exponential_function#computation_of_ab_where_both_a_and_b_are_complex)
* [ordinary trig functions](https://en.wikipedia.org/wiki/sine_and_cosine#complex_exponential_function_definitions)
* [inverse trig functions](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions#Extension_to_complex_plane)
* [hyperbolic trig functions](https://en.wikipedia.org/wiki/Hyperbolic_sin#Hyperbolic_functions_for_complex_numbers)
* [inverse hyperbolic trig functions](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions)

## Operands

Operands can take on any of these forms:
* Decimal - integer, floating point, scientific notation
* Binary - `0b` prefix, followed by digits `0` and `1`.
* Hexadecimal - `0x` prefix, followed by digits `0`-`9` and letters `a`-`f`.
* Complex - an ordered pair of numbers in any of the above formats. For example `1.2,-0x43` represents `1.2-67i`.

## Operators

The operator categories and certain exceptional functions show the domain over which they are valid.
* ℝ - real
* ℕ - natural
* ℂ - complex

### Basic Arithmetic - ℝ and ℂ
* <kbd>+</kbd>   - Addition
* <kbd>-</kbd>   - Subtraction
* <kbd>*</kbd>   - Multiplication
* <kbd>/</kbd>   - Division
* <kbd>div</kbd> - Integer division
* <kbd>%</kbd>   - Modulus (ℝ only)
* <kbd>abs</kbd> - Absolute value
* <kbd>arg</kbd> - The angle between X and the x-axis
* <kbd>chs</kbd> - Negation

### Powers & Logs - ℝ and ℂ
* <kbd>exp</kbd>   - Raise e to the X power
* <kbd>log</kbd>   - Natural Log of X
* <kbd>log10</kbd> - Log (base 10) of X
* <kbd>log2</kbd>  - Log (base 2) of X
* <kbd>sqrt</kbd>  - Square Root
* <kbd>**</kbd>    - Raise Y to the X power
* <kbd>\\</kbd>    - Reciprocal

### Trigonometry - ℝ and ℂ
* Sine      - <kbd>sin</kbd>   <kbd>asin</kbd>   <kbd>sinh</kbd>   <kbd>asinh</kbd>
* Cosine    - <kbd>cos</kbd>   <kbd>acos</kbd>   <kbd>cosh</kbd>   <kbd>acosh</kbd>
* Tangent   - <kbd>tan</kbd>   <kbd>atan</kbd>   <kbd>tanh</kbd>   <kbd>atanh</kbd>
* Cosecant  - <kbd>csc</kbd>   <kbd>acsc</kbd>   <kbd>csch</kbd>   <kbd>acsch</kbd>
* Secant    - <kbd>sec</kbd>   <kbd>asec</kbd>   <kbd>sech</kbd>   <kbd>asech</kbd>
* Cotangent - <kbd>cot</kbd>   <kbd>acot</kbd>   <kbd>coth</kbd>   <kbd>acoth</kbd>

### Rounding - ℝ and ℂ
* <kbd>floor</kbd> - Round down to nearest integer
* <kbd>ceil</kbd>  - Round up to nearest integer
* <kbd>round</kbd> - Round to nearest integer
* <kbd>trunc</kbd> - Truncate to integer

### Bitwise - ℕ
* <kbd>&</kbd>  - AND
* <kbd>\|</kbd> - OR
* <kbd>^</kbd>  - XOR
* <kbd>~</kbd>  - NOT
* <kbd><<</kbd> - Left Shift (Y shifted X places)
* <kbd>>></kbd> - Right Shift (Y shifted X places)

### Constants - ℝ and ℂ
* <kbd>pi</kbd>  - 3.141592653...
* <kbd>e</kbd>   - 2.718281828...
* <kbd>phi</kbd> - the golden ratio, 1.618033989...
* <kbd>i</kbd>   - 0+1i

### Miscellaneous - ℝ
* <kbd>hrs</kbd> - Convert (Z hours:Y minutes:X seconds) to X hours
* <kbd>hms</kbd> - Convert X hours to (Z hours:Y minutes:X seconds)
* <kbd>bin</kbd> - Print results in binary.
* <kbd>hex</kbd> - Print results in hexadecimal.

### Memory and Stack Manipulation - ℝ and ℂ
xm   - Store the value of X to memory
rm   - Recall the value in memory and put it on the stack
m+   - Add X to the value in memory
m-   - Subtract X from the value in memory
xy   - swap X and Y on the stack
x    - place the value of X from the last operation back on the stack
drop - take X off the stack

## Disclaimer
The author of this plugin does not make any warranties about the completeness, reliability and accuracy of this calculator. Any action you take upon the results you get from it, is strictly at your own risk. The author will not be liable for any losses and/or damages in connection with the use of this calculator.

## Feedback
It's quite possible that computational errors made their way in, despite all efforts to ensure accuracy. This was mainly an exercise to learn lua and Neovim plugins by porting my prior [Ruby and Erlang rpn calculators](https://github.com/PhilRunninger/rpn).

If you spot any errors, or have suggestions for improvements, added operators, etc., create an issue or a pull request.

Finally, I don't know how useful some of the complex number functions are. It was a fun exercise implementing them, but was it just that, an exercise? Leave a comment (in an issue is fine) if you know of any real-world (pun intended) use for, let's say, the hyperbolic arctangent of a complex number, or any of the others for that matter.
