# cmp-rpncalc
An [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for math calculations using Reverse Polish Notation

## Installation

Use your favorite plugin manager. If you don't have one, try one of these: [vim-pathogen](https://github.com/tpope/vim-pathogen), [vim-plug](https://github.com/junegunn/vim-plug), [Packer.nvim](https://github.com/wbthomason/packer.nvim) or [lazy.nvim](https://github.com/folke/lazy.nvim). Alternatively, you can use packages and submodules, as Greg Hurrell ([@wincent](https://github.com/wincent)) describes in his excellent Youtube video: [Vim screencast #75: Plugin managers](https://www.youtube.com/watch?v=X2_R3uxDN6g)

## Setup
There is no setup required specifically for this plugin; however, you need to add **rpncalc** to the list of sources in your **nvim-cmp** setup. The following snippet shows how to do that.
```lua
require'cmp'.setup {
  sources = {
    { name = 'rpncalc' }
  }
}
```

## How Does RPN Work?

RPN is a mathematical notation in which an operator follows its operand(s). This means there is no need for parentheses. Here are some examples, comparing algebraic notation to RPN.
| Algebraic | RPN (this plugin's flavor) | Result |
|:-:|:--|:-:|
| $73 + 37$ | `73 37 +` | `110` |
| $462\div11$ | `462 11 /` | `42` |
| $((1+2)*(3-4))^5$ | `1 2 + 3 4 - * 5 **` | `-243` |
| $\tan^{-1}(\frac{1}{\sqrt{3}})$ in degrees | `1 3 sqrt / atan deg` <br> or <br> `3 sqrt \ atan deg` | `30` |
| $3a^2+\frac{5}{a}$, where ${a=\frac{\sqrt{7}}{4}}$ | `7 sqrt 4 / sto 2 ** 3 * 5 rcl / +` | `8.8717894601845` |
| Euler's Identity: $e^{i\pi}+1=0$ | `e i pi * ** 1 +` | `0+1.2246467991474e-16i`<br>*round off error* 🙁 |

Reading an RPN expression from left to right, numbers are placed on a stack. The top four numbers are labeled `X`, `Y`, `Z`, and `T` from the top down. These labels are not shown when using the plugin, but they are referenced in the README and the documentation. When an operator is encountered, one or more numbers (as needed by the operator) are popped from the stack, and the result of the operation is pushed back onto the stack.

## Complex Numbers
Most of the operators will work on complex numbers. The following Wikipedia pages were used as reference for some of the more arcane complex numbers calculations. Where the complete answer is an infinte number of values, only the principal value is given.
* [logarithms](https://en.wikipedia.org/wiki/Complex_logarithm)
* [exponentiation](https://en.wikipedia.org/wiki/exponential_function#computation_of_ab_where_both_a_and_b_are_complex)
* [ordinary trig functions](https://en.wikipedia.org/wiki/sine_and_cosine#complex_exponential_function_definitions)
* [inverse trig functions](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions#Extension_to_complex_plane)
* [hyperbolic trig functions](https://en.wikipedia.org/wiki/Hyperbolic_sin#Hyperbolic_functions_for_complex_numbers)
* [inverse hyperbolic trig functions](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions)

## Operands

Operands can take on any of these forms:
* Decimal (base 10): integer, decimal, or scientific notation
* Binary (base 2): `0b` prefix, followed by digits `0` and `1`.
* Hexadecimal (base 16): `0x` prefix, followed by digits `0`-`9` and letters `a`-`f`.
* Complex: an ordered pair of numbers in any of the prior formats. For example `1.2,-0x43` represents `1.2-67i` in decimal notation.

## Operators

The **Domain** column in the following table indicates the types of numbers that are valid for each operator. The possible domains are:
* **ℕ**atural - natural (non-negative) integers
* **ℝ**eal - real numbers (includes **ℕ**)
* **ℂ**omplex - complex numbers (includes **ℝ** and **ℕ**)

| Operator         | Function                                                                                 | Domain |
| :-:              | ---                                                                                      | :-:    |
|| <br>**Basic Arithmetic**||
| <kbd>+</kbd>     | Addition                                                                                 | **ℂ**omplex |
| <kbd>-</kbd>     | Subtraction                                                                              | **ℂ**omplex |
| <kbd>\*</kbd>    | Multiplication                                                                           | **ℂ**omplex |
| <kbd>/</kbd>     | Division                                                                                 | **ℂ**omplex |
| <kbd>div</kbd>   | Integer division                                                                         | **ℂ**omplex |
| <kbd>%</kbd>     | Modulus *(not well-defined for negatives)*                                               | **ℝ**eal |
| <kbd>abs</kbd>   | Absolute value                                                                           | **ℂ**omplex |
| <kbd>arg</kbd>   | Argument *(the angle between X and the positive real axis)*                              | **ℂ**omplex |
| <kbd>chs</kbd>   | Change Sign *(negation)*                                                                 | **ℂ**omplex |
|| <br>**Powers & Logs**||
| <kbd>exp</kbd>   | Raise e to the X power                                                                   | **ℂ**omplex |
| <kbd>ln</kbd>    | Natural Log of X                                                                         | **ℂ**omplex |
| <kbd>log</kbd>   | Log (base 10) of X                                                                       | **ℂ**omplex |
| <kbd>log2</kbd>  | Log (base 2) of X                                                                        | **ℂ**omplex |
| <kbd>sqrt</kbd>  | Square Root                                                                              | **ℂ**omplex |
| <kbd>\*\*</kbd>  | Raise Y to the X power                                                                   | **ℂ**omplex |
| <kbd>\\</kbd>    | Reciprocal                                                                               | **ℂ**omplex |
|| <br>**Trigonometry** *Variations are: <kbd>a...</kbd> for inverse and <kbd>...h</kbd> for hyperbolic* ||
| <kbd>sin</kbd>   | Sine, <kbd>asin</kbd>, <kbd>sinh</kbd>, <kbd>asinh</kbd>                                 | **ℂ**omplex |
| <kbd>cos</kbd>   | Cosine, <kbd>acos</kbd>, <kbd>cosh</kbd>, <kbd>acosh</kbd>                               | **ℂ**omplex |
| <kbd>tan</kbd>   | Tangent, <kbd>atan</kbd>, <kbd>tanh</kbd>, <kbd>atanh</kbd>                              | **ℂ**omplex |
| <kbd>csc</kbd>   | Cosecant, <kbd>acsc</kbd>, <kbd>csch</kbd>, <kbd>acsch</kbd>                             | **ℂ**omplex |
| <kbd>sec</kbd>   | Secant, <kbd>asec</kbd>, <kbd>sech</kbd>, <kbd>asech</kbd>                               | **ℂ**omplex |
| <kbd>cot</kbd>   | Cotangent, <kbd>acot</kbd>, <kbd>coth</kbd>, <kbd>acoth</kbd>                            | **ℂ**omplex |
|| <br>**Rounding**||
| <kbd>floor</kbd> | Round down to nearest integer                                                            | **ℂ**omplex |
| <kbd>ceil</kbd>  | Round up to nearest integer                                                              | **ℂ**omplex |
| <kbd>round</kbd> | Round up or down to nearest integer                                                      | **ℂ**omplex |
| <kbd>trunc</kbd> | Round toward zero to nearest integer                                                     | **ℂ**omplex |
|| <br>**Bitwise** *Non-integer operands will be truncated.*||
| <kbd>&</kbd>     | AND &nbsp; &nbsp; &nbsp; $\footnotesize0b\normalsize1100\text{ AND }\footnotesize0b\normalsize1010=\footnotesize0b\normalsize1000$ &nbsp; &nbsp; &nbsp; $12\text{ AND }10=8$                                    | **ℕ**atural |
| <kbd>\|</kbd>    | OR &nbsp; &nbsp; &nbsp; $\footnotesize0b\normalsize1100\text{ OR }\footnotesize0b\normalsize1010=\footnotesize0b\normalsize1110$ &nbsp; &nbsp; &nbsp; $12\text{ OR }10=14$                                      | **ℕ**atural |
| <kbd>^</kbd>     | XOR &nbsp; &nbsp; &nbsp; $\footnotesize0b\normalsize1100\text{ XOR }\footnotesize0b\normalsize1010=\footnotesize0b\normalsize0110$ &nbsp; &nbsp; &nbsp; $12\text{ XOR }10=6$                                    | **ℕ**atural |
| <kbd>~</kbd>     | NOT &nbsp; &nbsp; &nbsp; $\text{NOT }\footnotesize0b\normalsize1010=\footnotesize0b\normalsize101$ &nbsp; &nbsp; &nbsp; $\text{NOT }10=5$                                                                       | **ℕ**atural |
| <kbd><<</kbd>    | Left Shift *(Y shifted X bits)* &nbsp; &nbsp; &nbsp; ${\footnotesize0b\normalsize1\overleftarrow{11}}^{\text{ }2}=\footnotesize0b\normalsize11100$ &nbsp; &nbsp; &nbsp; ${\overleftarrow{7}}^{\text{ }2}=28$    | **ℕ**atural |
| <kbd>>></kbd>    | Right Shift *(Y shifted X bits)* &nbsp; &nbsp; &nbsp; ${\footnotesize0b\normalsize110\overrightarrow{10}}^{\text{ }2}=\footnotesize0b\normalsize110$ &nbsp; &nbsp; &nbsp; ${\overrightarrow{26}}^{\text{ }2}=6$ | **ℕ**atural |
|| <br>**Statistics**||
| <kbd>!</kbd>     | Factorial of X &nbsp; &nbsp; &nbsp; $X!={\prod^{X}_{i=1}{i}}$                                                                       | **ℕ**atural |
| <kbd>perm</kbd>  | Permutation of Y things taken X at a time &nbsp; &nbsp; &nbsp; $_YP_X={\frac{Y!}{(Y-X)!}}$                                          | **ℕ**atural |
| <kbd>comb</kbd>  | Combination of Y things taken X at a time &nbsp; &nbsp; &nbsp; $_YC_X={\frac{Y!}{X!(Y-X)!}}$                                        | **ℕ**atural |
| <kbd>n</kbd>     | Sample size *(size of the stack)*                                                                                                   | **ℂ**omplex |
| <kbd>mean</kbd>  | Average of all numbers on the stack. &nbsp; &nbsp; &nbsp; $\bar{x}={\frac{1}{n}}{\sum^{n}_{i=1}{x_i}}$                              | **ℂ**omplex |
| <kbd>sum</kbd>   | Sum of all numbers on the stack &nbsp; &nbsp; &nbsp; ${\sum^{n}_{i=1}{x_i}}$                                                        | **ℂ**omplex |
| <kbd>ssq</kbd>   | Sum of squares of all numbers on the stack &nbsp; &nbsp; &nbsp; ${\sum^{n}_{i=1}{x_i}^2}$                                           | **ℂ**omplex |
| <kbd>std</kbd>   | Sample standard deviation of all numbers on the stack &nbsp; &nbsp; &nbsp; $s={\sqrt{\frac{{\sum^{n}_{i=1}(x_i-\bar{x})^2}}{n-1}}}$ | **ℝ**eal |
|| <br>**Miscellaneous**||
| <kbd>hrs</kbd>   | Convert (Z hours:Y minutes:X seconds) to X hours                                                | **ℝ**eal |
| <kbd>hms</kbd>   | Convert X hours to (Z hours:Y minutes:X seconds)                                                | **ℝ**eal |
| <kbd>bin</kbd>   | Print results in binary (base 2).                                                               | **ℝ**eal |
| <kbd>hex</kbd>   | Print results in hexadecimal (base 16).                                                         | **ℝ**eal |
| <kbd>dec</kbd>   | Print results in decimal (base 10).                                                             | **ℝ**eal |
|| <br>**Constants**||
| <kbd>pi</kbd>    | Ratio of circumference to diameter &nbsp; &nbsp; &nbsp; $\pi={3.1415926535898...}$              | **ℝ**eal |
| <kbd>e</kbd>     | Euler's number &nbsp; &nbsp; &nbsp; $e={\sum^{\infty}_{i=0}{\frac{1}{i!}}=2.7182818284590...}$  | **ℝ**eal |
| <kbd>phi</kbd>   | The golden ratio &nbsp; &nbsp; &nbsp; $\phi={\frac{\sqrt{5}+1}{2}}=1.6180339887499...$          | **ℝ**eal |
| <kbd>i</kbd>     | The imaginary unit number &nbsp; &nbsp; &nbsp; $i={\sqrt{-1}}$                                  | **ℂ**omplex |
|| <br>**Memory and Stack Manipulation**||
| <kbd>sto</kbd>   | Store the value of X to memory                                                                  | **ℂ**omplex |
| <kbd>rcl</kbd>   | Recall the value in memory to the stack                                                         | **ℂ**omplex |
| <kbd>m+</kbd>    | Add X to the value in memory                                                                    | **ℂ**omplex |
| <kbd>m-</kbd>    | Subtract X from the value in memory                                                             | **ℂ**omplex |
| <kbd>xy</kbd>    | Swap X and Y on the stack                                                                       | **ℂ**omplex |
| <kbd>x</kbd>     | Place the value of X from the last operation back on the stack                                  | **ℂ**omplex |
| <kbd>drop</kbd>  | Remove X from the stack                                                                         | **ℂ**omplex |

## Disclaimer ⚠
The author of this plugin makes no warranties about the completeness, reliability or accuracy of this calculator. Any action you take upon the results you get from it is strictly at your own risk. The author will not be liable for any losses and/or damages in connection with the use of this calculator.

## Feedback 📣
This was mainly an exercise to learn lua, and to write a Neovim plugin by porting my prior [Ruby and Erlang rpn calculators](https://github.com/PhilRunninger/rpn). It's quite possible that computational errors made their way in, despite all efforts to ensure its accuracy. If you spot any errors, or have suggestions for improvements, new operators, etc., create an issue or a pull request.

Finally, I don't know how useful some of the complex number functions are. It was a fun exercise implementing them, but was it just that, an exercise? Leave a comment if you know of any real-world use (pun intended) for perhaps, the inverse hyperbolic cotangent of a complex number.
