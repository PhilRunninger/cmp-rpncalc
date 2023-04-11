# cmp-rpncalc
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for math calculations using Reverse Polish Notation

## Installation

Use your favorite plugin manager to install this plugin. [vim-pathogen](https://github.com/tpope/vim-pathogen), [vim-plug](https://github.com/junegunn/vim-plug), and [Packer.nvim](https://github.com/wbthomason/packer.nvim) are some of the more popular ones. A lengthy discussion of these and other managers can be found on [vi.stackexchange.com](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).

If you have no favorite, or want to manage your plugins without 3rd-party dependencies, use packages, as described in Greg Hurrell's excellent Youtube video: [Vim screencast #75: Plugin managers](https://www.youtube.com/watch?v=X2_R3uxDN6g)

## Setup
Add **rpncalc** to the list of sources in your **nvim-cmp** setup, as shown in the following snippet.
```
require'cmp'.setup {
  sources = {
    { name = 'rpncalc' }
  }
}
```

## How Does RPN Work?

RPN is a mathematical notation in which the operator follows its operand(s). This means there is no need for parentheses. Here are some examples:
* Add 956 and 37: `956 37 +`
* Divide 452 by 12 (Remember, the order of operands is important.): `452 12 /`
* Find the arctangent of 1/√3: `3 sqrt \ atan deg`
* Evaluate `3x²+13x-10` at `x=4`:
    * `3 4 2 ** * 13 4 * + 10 -`

Reading an expression from left to right, numbers are placed on a stack. The top four numbers are labeled `X`, `Y`, `Z`, and `T` from the top down. Although these labels are not shown when using the plugin, they are referenced in the README and the documentation. When an operator is encountered, one or more numbers (as needed by the operator) are popped from the stack, and the result of the operation is pushed back on the stack.

## Complex Numbers
Most of the operators also will process complex numbers. The following web pages were used as reference for some of the more arcane derivations for complex numbers. Where the complete answer is an infinte number of answers, only the principal value is given. *As a side note, I don't know how useful these functions are, but it was a fun exercise implementing them. Leave a comment if you know of any practical use for, let's say, the hyperbolic arctangent of a complex number.*
* [logarithms](https://en.wikipedia.org/wiki/Complex_logarithm)
* [exponentiation](https://www.wikiwand.com/en/exponential_function#computation_of_ab_where_both_a_and_b_are_complex)
* [ordinary trig functions](https://en.wikipedia.org/wiki/sine_and_cosine#complex_exponential_function_definitions)
* [inverse trig functions](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions#Extension_to_complex_plane)
* [hyperbolic trig functions](https://en.wikipedia.org/wiki/Hyperbolic_sin#Hyperbolic_functions_for_complex_numbers)
* [inverse hyperbolic trig functions](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions)

## Operands

Numbers can be entered as integers, decimals, or in scientific notation. Complex numbers are entered as an ordered pair: `real,imaginary`. For example `1.2,3` represents `1.2+3i`.

## Operators

The ones marked with a ⭑ will work with complex operands.

| Basic Arithmetic |                         | Powers & Logs     |                        |
| :-:              | ---                     | :-:               | ---                    |
| <kbd>+</kbd>⭑    | Addition                | <kbd>exp</kbd>⭑   | Raise e to the X power |
| <kbd>-</kbd>⭑    | Subtraction             | <kbd>log</kbd>⭑   | Natural Log of X       |
| <kbd>*</kbd>⭑    | Multiplication          | <kbd>log10</kbd>⭑ | Log (base 10) of X     |
| <kbd>/</kbd>⭑    | Division                | <kbd>log2</kbd>⭑  | Log (base 2) of X      |
| <kbd>div</kbd>   | Integer division        | <kbd>sqrt</kbd>⭑  | Square Root            |
| <kbd>%</kbd>     | Modulus                 | <kbd>**</kbd>⭑    | Raise Y to the X power |
| <kbd>abs</kbd>⭑  | Absolute value          | <kbd>\\</kbd>⭑    | Reciprocal             |
| <kbd>arg</kbd>⭑  | The angle between X and the x-axis (complex only) |        |         |
| <kbd>chs</kbd>⭑  | Negation                |                   |                        |

| Trigonometry | Base            | Inverse          | Hyperbolic       | Inverse Hyperbolic |
| ---          | :-:             | :-:              | :-:              | :-:                |
| Sine         | <kbd>sin</kbd>⭑ | <kbd>asin</kbd>⭑ | <kbd>sinh</kbd>⭑ | <kbd>asinh</kbd>⭑  |
| Cosine       | <kbd>cos</kbd>⭑ | <kbd>acos</kbd>⭑ | <kbd>cosh</kbd>⭑ | <kbd>acosh</kbd>⭑  |
| Tangent      | <kbd>tan</kbd>⭑ | <kbd>atan</kbd>⭑ | <kbd>tanh</kbd>⭑ | <kbd>atanh</kbd>⭑  |
| Cosecant     | <kbd>csc</kbd>⭑ | <kbd>acsc</kbd>⭑ | <kbd>csch</kbd>⭑ | <kbd>acsch</kbd>⭑  |
| Secant       | <kbd>sec</kbd>⭑ | <kbd>asec</kbd>⭑ | <kbd>sech</kbd>⭑ | <kbd>asech</kbd>⭑  |
| Cotangent    | <kbd>cot</kbd>⭑ | <kbd>acot</kbd>⭑ | <kbd>coth</kbd>⭑ | <kbd>acoth</kbd>⭑  |

| Bitwise       |                                  | Rounding          |                               |
| :-:           | ---                              | :-:               | ---                           |
| <kbd>&</kbd>  | AND                              | <kbd>floor</kbd>⭑ | Round down to nearest integer |
| <kbd>\|</kbd> | OR                               | <kbd>ceil</kbd>⭑  | Round up to nearest integer   |
| <kbd>^</kbd>  | XOR                              | <kbd>round</kbd>⭑ | Round to nearest integer      |
| <kbd><<</kbd> | Left Shift (Y shifted X places)  | <kbd>trunc</kbd>⭑ | Truncate to integer           |
| <kbd>>></kbd> | Right Shift (Y shifted X places) |                   |                               |
| <kbd>~</kbd>  | 1's complement                   |                   |                               |

| Constants      |                 | Other          |                          |
| :-:            | ---             | :-:            | ---                      |
| <kbd>pi</kbd>  | 3.141592653.... | <kbd>hrs</kbd> | Convert Z:Y:X to hours   |
| <kbd>e</kbd>   | 2.718281828...  | <kbd>hms</kbd> | Convert X hours to Z:Y:X |
| <kbd>phi</kbd> | 0.618033989...  |                |                          |
| <kbd>i</kbd>   | 0+1i            |                |                          |

## Errors and Enhancements
Please don't use this for important calculations, or at the very least double-check them with another calculator. It's quite possible computational errors made their way in, despite all efforts to ensure accuracy. This was mainly an exercise to learn lua and Neovim plugins by porting my prior [Ruby and Erlang rpn calculators](https://github.com/PhilRunninger/rpn).

If you spot any errors, or have suggestions for improvements, added operators, etc., create an issue or a pull request.
