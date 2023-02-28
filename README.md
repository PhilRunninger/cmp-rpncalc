# cmp-rpncalc
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for math calculations using Reverse Polish Notation

## Installation

Use your favorite plugin manager to install this plugin. [vim-pathogen](https://github.com/tpope/vim-pathogen), [Vundle.vim](https://github.com/VundleVim/Vundle.vim), [vim-plug](https://github.com/junegunn/vim-plug), [neobundle.vim](https://github.com/Shougo/neobundle.vim), and [Packer.nvim](https://github.com/wbthomason/packer.nvim) are some of the more popular ones. A lengthy discussion of these and other managers can be found on [vi.stackexchange.com](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).

If you have no favorite, or want to manage your plugins without 3rd-party dependencies, I recommend using packages, as described in Greg Hurrell's excellent Youtube video: [Vim screencast #75: Plugin managers](https://www.youtube.com/watch?v=X2_R3uxDN6g)

## Setup

```
require'cmp'.setup {
  formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
          vim_item.menu = ({
              nvim_lsp = "[LSP]",
              nvim_lua = "[NVIM_LUA]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
              rpncalc = "[RPN]",
          })[entry.source.name]
          return vim_item
      end,
  },
  sources = {
    { name = 'rpncalc' }
  }
}
```

## How Does RPN Work?

RPN is a mathematical notation in which the operator follows its operand(s). This means there is no need for parentheses. Here are some examples:
* Add 956 and 37: `956 37 +`
* Divide 452 by 12 (Remember, division isn't commutative.): `452 12 /`
* Find the tangent of 28 degrees: `28 rad tan`
* Solve `3x²+13x-10 = 0` using the quadratic formula:
    * `13 chs 13 2 ** 4 3 10 chs * * - sqrt + 2 3 * /`
    * `13 chs 13 2 ** 4 3 10 chs * * - sqrt - 2 3 * /`

Reading an expression from left to right, numbers are placed on a stack. When an operator is encountered one or more numbers (as needed by the operator) are popped from the stack and the result of the operation is pushed back on the stack.

## Operands

Numbers can be entered as integers, decimals, or in scientific notation.

## Operators

| Basic Arithmetic |                  | Powers & Logs    |                        |
| :-:              | ---              | :-:              | ---                    |
| <kbd>+</kbd>     | Addition         | <kbd>exp</kbd>   | Raise e to the x power |
| <kbd>-</kbd>     | Subtraction      | <kbd>log</kbd>   | Natural Log of x       |
| <kbd>*</kbd>     | Multiplication   | <kbd>log10</kbd> | Log (base 10) of x     |
| <kbd>/</kbd>     | Division         | <kbd>log2</kbd>  | Log (base 2) of x      |
| <kbd>div</kbd>   | Integer division | <kbd>sqrt</kbd>  | Square Root            |
| <kbd>%</kbd>     | Modulus          | <kbd>**</kbd>    | Exponentiation         |
| <kbd>abs</kbd>   | Absolute value   | <kbd>\</kbd>     | Reciprocal             |
| <kbd>chs</kbd>   | Negation         |                  |                        |

| Trigonometry | Base           | Inverse         | Hyperbolic      | Inverse Hyperbolic |
| ---          | :-:            | :-:             | :-:             | :-:                |
| Sine         | <kbd>sin</kbd> | <kbd>asin</kbd> | <kbd>sinh</kbd> | <kbd>asinh</kbd>   |
| Cosine       | <kbd>cos</kbd> | <kbd>acos</kbd> | <kbd>cosh</kbd> | <kbd>acosh</kbd>   |
| Tangent      | <kbd>tan</kbd> | <kbd>atan</kbd> | <kbd>tanh</kbd> | <kbd>atanh</kbd>   |
| Cosecant     | <kbd>csc</kbd> | <kbd>acsc</kbd> | <kbd>csch</kbd> | <kbd>acsch</kbd>   |
| Secant       | <kbd>sec</kbd> | <kbd>asec</kbd> | <kbd>sech</kbd> | <kbd>asech</kbd>   |
| Cotangent    | <kbd>cot</kbd> | <kbd>acot</kbd> | <kbd>coth</kbd> | <kbd>acoth</kbd>   |

| Bitwise       |                | Rounding         |                               |
| :-:           | ---            | :-:              | ---                           |
| <kbd>&</kbd>  | AND            | <kbd>floor</kbd> | Round down to nearest integer |
| <kbd>\| </kbd>| OR             | <kbd>ceil</kbd>  | Round up to nearest integer   |
| <kbd>^</kbd>  | XOR            | <kbd>round</kbd> | Round to nearest integer      |
| <kbd><<</kbd> | Left Shift     | <kbd>trunc</kbd> | Truncate to integer           |
| <kbd>>></kbd> | Right Shift    |                  |                               |
| <kbd>~</kbd>  | 1's complement |                  |                               |

| Constants      |                 | Other          |                          |
| :-:            | ---             | :-:            | ---                      |
| <kbd>pi</kbd>  | 3.141592653.... | <kbd>hrs</kbd> | Convert Z:Y:X to hours   |
| <kbd>e</kbd>   | 2.718281828...  | <kbd>hms</kbd> | Convert X hours to Z:Y:X |
| <kbd>phi</kbd> | 0.618033989...  |                |                          |
