# cmp-rpncalc
An [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for math calculations using Reverse Polish Notation

## Installation

Use your favorite plugin manager. If you don't have one, try one of these: [vim-pathogen](https://github.com/tpope/vim-pathogen), [vim-plug](https://github.com/junegunn/vim-plug), [Packer.nvim](https://github.com/wbthomason/packer.nvim) or [lazy.nvim](https://github.com/folke/lazy.nvim). Alternatively, you can use packages and submodules, as Greg Hurrell ([@wincent](https://github.com/wincent)) describes in his excellent Youtube video: [Vim screencast #75: Plugin managers](https://www.youtube.com/watch?v=X2_R3uxDN6g)

## Setup
There is no setup required specifically for this plugin; however, you need to add **rpncalc** to the list of sources in your **nvim-cmp** setup. The following snippet shows how to do that.
```lua
require'cmp'.setup {
  sources = {
    { name = 'rpncalc' }   -- Add this to the sources list.
  }
}
```

## How Does RPN Work?

RPN is a mathematical notation in which an operator follows its operand(s). This means there is no need for parentheses. Here are some examples, comparing algebraic notation to RPN.
| Algebraic | RPN (this plugin's flavor)
|:--|:--|
| $73 + 37=110$ | `73 37 +` |
| $462\div11=42$ | `462 11 /` |
| $\lvert((1+2)\times(3-4))^5\rvert=243$ | `1 2 + 3 4 - * 5 ** abs` |
| $\tan^{-1}(\frac{1}{\sqrt{3}})=30^\circ$| `1 3 sqrt / atan deg` <br> or <br> `3 sqrt \ atan deg` |
| If ${a=\frac{\sqrt{7}}{4}}$, $48a^2-\frac{98}{a^4}=-491$ | `7 sqrt 4 / sto 2 ** 48 * 98 rcl 4 ** / -` |
| Euler's Identity: $e^{i\pi}+1=0$ | `e i pi * ** 1 +`<br>Round-off error gives the answer $\scriptsize{0+1.2246467991474\times{10}^{-16}i}$. |

Reading an RPN expression from left to right, numbers are placed on a stack. The top four numbers are labeled **X**, **Y**, **Z**, and **T** from the top down. These labels are not shown when using the plugin, but they are referenced in the README and the documentation. When an operator is encountered, one or more numbers (as needed by the operator) are popped from the stack, and the result of the operation is pushed back onto the stack.

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
* Decimal (base 10): integer `42`, float `-3.14`, or scientific notation `6.02e23`
* Binary (base 2): `0b` prefix, followed by digits `0` and `1`.
* Hexadecimal (base 16): `0x` prefix, followed by digits `0`-`9` or letters `a`-`f` or `A`-`F`.
* Complex: an ordered pair of numbers in any of the prior formats. For example,<br>`1.2e-4,0x43` equates to `0.00012+67i` in decimal notation.

## Operators

The **Domain** column in the following table indicates the types of numbers that are valid for each operator. The possible domains are:
* ℕatural - non-negative integers
* ℝeal - real numbers (includes ℕatural)
* ℂomplex - complex numbers (includes ℝeal and ℕatural)

| Operator | Function | Domain |
| :-:      | ---      | :-:    |
|                | <br>**Basic Arithmetic**                                          |         |
| <kbd>+</kbd>   | Addition                                                          | ℂomplex |
| <kbd>-</kbd>   | Subtraction                                                       | ℂomplex |
| <kbd>\*</kbd>  | Multiplication                                                    | ℂomplex |
| <kbd>/</kbd>   | Division                                                          | ℂomplex |
| <kbd>div</kbd> | Integer division                                                  | ℂomplex |
| <kbd>%</kbd>   | Modulus *(not well-defined for negatives)*                        | ℝeal    |
| <kbd>abs</kbd> | Absolute value                                                    | ℂomplex |
| <kbd>arg</kbd> | Argument *(the angle between* **X** *and the positive real axis)* | ℂomplex |
| <kbd>chs</kbd> | Change Sign *(negation)*                                          | ℂomplex |
|                 | <br>**Powers & Logs**          |         |
| <kbd>\*\*</kbd> | Raise **Y** to the **X** power | ℂomplex |
| <kbd>\\</kbd>   | Reciprocal                     | ℂomplex |
| <kbd>exp</kbd>  | Raise e to the **X** power     | ℂomplex |
| <kbd>ln</kbd>   | Natural Log of **X**           | ℂomplex |
| <kbd>log</kbd>  | Log (base 10) of **X**         | ℂomplex |
| <kbd>log2</kbd> | Log (base 2) of **X**          | ℂomplex |
| <kbd>sqrt</kbd> | Square Root                    | ℂomplex |
|                | <br>**Trigonometry** *Variations are: <kbd>a...</kbd> for inverse and <kbd>...h</kbd> for hyperbolic* |         |
| <kbd>sin</kbd> | Sine, <kbd>asin</kbd>, <kbd>sinh</kbd>, <kbd>asinh</kbd>                                              | ℂomplex |
| <kbd>cos</kbd> | Cosine, <kbd>acos</kbd>, <kbd>cosh</kbd>, <kbd>acosh</kbd>                                            | ℂomplex |
| <kbd>tan</kbd> | Tangent, <kbd>atan</kbd>, <kbd>tanh</kbd>, <kbd>atanh</kbd>                                           | ℂomplex |
| <kbd>csc</kbd> | Cosecant, <kbd>acsc</kbd>, <kbd>csch</kbd>, <kbd>acsch</kbd>                                          | ℂomplex |
| <kbd>sec</kbd> | Secant, <kbd>asec</kbd>, <kbd>sech</kbd>, <kbd>asech</kbd>                                            | ℂomplex |
| <kbd>cot</kbd> | Cotangent, <kbd>acot</kbd>, <kbd>coth</kbd>, <kbd>acoth</kbd>                                         | ℂomplex |
|                  | <br>**Rounding**                     |         |
| <kbd>floor</kbd> | Round down to nearest integer        | ℂomplex |
| <kbd>ceil</kbd>  | Round up to nearest integer          | ℂomplex |
| <kbd>round</kbd> | Round up or down to nearest integer  | ℂomplex |
| <kbd>trunc</kbd> | Round toward zero to nearest integer | ℂomplex |
|                  | <br>**Bitwise** *Non-integer operands will be truncated.* |         |
| <kbd>&</kbd>     | AND &nbsp; &nbsp; $0b1100\text{ AND }0b{1010}=0b1000$ &nbsp; &nbsp; $12\text{ AND }10=8$                                                 | ℕatural |
| <kbd>\|</kbd>    | OR &nbsp; &nbsp; $0b1100\text{ OR }0b1010=0b1110$ &nbsp; &nbsp; $12\text{ OR }10=14$                                                   | ℕatural |
| <kbd>^</kbd>     | XOR &nbsp; &nbsp; $0b1100\text{ XOR }0b1010=0b0110$ &nbsp; &nbsp; $12\text{ XOR }10=6$                                                 | ℕatural |
| <kbd>~</kbd>     | NOT &nbsp; &nbsp; $\text{NOT }0b1010=-0b1011$ &nbsp; &nbsp; $\text{NOT }10=-11$<br>All bits are flipped, and a [two's complement conversion](https://en.wikipedia.org/wiki/Two's_complement#Converting_from_two's_complement_representation) of the result is displayed.<br>$58 = 0b00111010$<br>$\text{[NOT}\rightarrow\text{] } = 0b11000101$<br>$\text{[2's complement}\rightarrow\text{] } = -2^7+2^6+2^2+2^0=-128+64+4+1=-59$ | ℕatural |
| <kbd><<</kbd>    | Left Shift _(_**Y** *shifted* **X** *bits)* &nbsp; &nbsp; ${0b1\overleftarrow{11}}^{\text{ }2}=0b11100$ &nbsp; &nbsp; $\overleftarrow{7}^2=28$     | ℕatural |
| <kbd>>></kbd>    | Right Shift _(_**Y** *shifted* **X** *bits)* &nbsp; &nbsp; ${0b110\overrightarrow{100}}^{\text{ }3}=0b110$ &nbsp; &nbsp; $\overrightarrow{52}^3=6$ | ℕatural |
|                 | <br>**Statistics**                                                                                                                         |         |
| <kbd>!</kbd>    | Factorial of **X** &nbsp; &nbsp; $X!=\prod_{i=1}^{X}{i}$                                                                   | ℕatural |
| <kbd>perm</kbd> | Permutation of **Y** things taken **X** at a time &nbsp; &nbsp; $_YP_X={\frac{Y!}{(Y-X)!}}$                                         | ℕatural |
| <kbd>comb</kbd> | Combination of **Y** things taken **X** at a time &nbsp; &nbsp; $_YC_X={\frac{Y!}{X!(Y-X)!}}$                                       | ℕatural |
| <kbd>n</kbd>    | Sample size *(size of the stack)*                                                                                                          | ℂomplex |
| <kbd>mean</kbd> | Average of all numbers on the stack. &nbsp; &nbsp; $\bar{x}={\frac{1}{n}}{\sum_{i=1}^n{x_i}}$                              | ℂomplex |
| <kbd>sum</kbd>  | Sum of all numbers on the stack &nbsp; &nbsp; $\sum_{i=1}^n{x_i}$                                                        | ℂomplex |
| <kbd>ssq</kbd>  | Sum of squares of all numbers on the stack &nbsp; &nbsp; $\sum_{i=1}^n{x_i}^2$                                           | ℂomplex |
| <kbd>std</kbd>  | Sample standard deviation of all numbers on the stack &nbsp; &nbsp; $s=\sqrt{\frac{{\sum_{i=1}^{n}(x_i-\bar{x})^2}}{n-1}}$ | ℝeal    |
|                | <br>**Miscellaneous**                                            |      |
| <kbd>hrs</kbd> | Convert (**Z** hours:**Y** minutes:**X** seconds) to **X** hours | ℝeal |
| <kbd>hms</kbd> | Convert **X** hours to (**Z** hours:**Y** minutes:**X** seconds) | ℝeal |
| <kbd>gcd</kbd> | Greatest Common Divisor of **X** and **Y** | ℕatural |
| <kbd>lcm</kbd> | Least Common Multiple of **X** and **Y** | ℕatural |
| <kbd>dec</kbd> | Print result in decimal (base 10)                                | ℂomplex |
| <kbd>hex</kbd> | Print result in hexadecimal (base 16) $^*$                       | ℂomplex |
| <kbd>bin</kbd> | Print result in binary (base 2) $^*$                             | ℂomplex |
|                  | $^*$ Non-integer values are truncated. Negatives are formatted as human readable:<br> $-23=-0b10111=-0x17$<br>as opposed to<br>$0b1...1111111111111111111111111101001$ or $0x\text{F...FFFFFE9}$            | |
|                | <br>**Constants**                                                                                     |         |
| <kbd>pi</kbd>  | Ratio of a circle's circumference to its diameter &nbsp; &nbsp; $\pi={3.1415926535898...}$         | ℝeal    |
| <kbd>e</kbd>   | Euler's number &nbsp; &nbsp; $e=\sum_{i=0}^\infty{\frac{1}{i!}}=2.7182818284590...$ | ℝeal    |
| <kbd>phi</kbd> | The golden ratio &nbsp; &nbsp; $\phi={\frac{\sqrt{5}+1}{2}}=1.6180339887499...$                | ℝeal    |
| <kbd>i</kbd>   | The imaginary unit number &nbsp; &nbsp; $i={\sqrt{-1}}$                                        | ℂomplex |
|                 | <br>**Memory and Stack Manipulation**                              |         |
| <kbd>sto</kbd>  | Store the value of **X** to memory                                 | ℂomplex |
| <kbd>rcl</kbd>  | Recall the value in memory to the stack                            | ℂomplex |
| <kbd>m+</kbd>   | Add **X** to the value in memory                                   | ℂomplex |
| <kbd>m-</kbd>   | Subtract **X** from the value in memory                            | ℂomplex |
| <kbd>xy</kbd>   | Swap **X** and **Y** on the stack                                  | ℂomplex |
| <kbd>x</kbd>    | Place the value of **X** from the last operation back on the stack | ℂomplex |
| <kbd>drop</kbd> | Remove **X** from the stack                                        | ℂomplex |

## Disclaimer ⚠
The author of this plugin makes no warranties about the completeness, reliability or accuracy of this calculator. Any action you take upon the results you get from it is strictly at your own risk. The author will not be liable for any losses and/or damages in connection with the use of this calculator.

## Feedback 📣
This was mainly an exercise to learn lua, and to write a Neovim plugin by porting my prior [Ruby and Erlang rpn calculators](https://github.com/PhilRunninger/rpn). It's quite possible that computational errors made their way in, despite all efforts to ensure the plugin's accuracy. If you spot any errors, or have suggestions for improvements, new operators, etc., create an issue or a pull request.

Finally, I don't know how useful some of the complex number functions are. It was a fun exercise implementing them, but was it just that - an exercise? Leave a comment if you know of any real-world use (pun intended) for perhaps, the inverse hyperbolic cotangent of a complex number.
