[![CI](https://github.com/bradhowes/swift-math-parser/workflows/CI/badge.svg)](https://github.com/bradhowes/swift-math-parser)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/ad941184ed256708952a2057fc5d7bb4/raw/swift-math-parser-coverage.json)](https://github.com/bradhowes/swift-math-parser/blob/main/.github/workflows/CI.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fswift-math-parser%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bradhowes/swift-math-parser)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2Fswift-math-parser%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bradhowes/swift-math-parser)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# swift-math-parser

Basic math expression parser built with [Point•Free's](https://www.pointfree.co/)
[swift-parsing](https://github.com/pointfreeco/swift-parsing) package (v0.12.0).

NOTE: v3.1.0 uses swift-parsing v0.12 which requires Xcode 14 and ideally Swift 5.8 
(see [What's Changed](https://github.com/pointfreeco/swift-parsing/releases/tag/0.12.0) for additional details).
If you need to use an older version, use the tagged 3.0.1 release instead.

```swift
let parser = MathParser()
let evaluator = parser.parse('4 × sin(t × π) + 2 × sin(t × π)')
evaluator.eval("t", value: 0.0) // => 0.0
evaluator.eval("t", value: 0.25) // => 4.2426406871192848
evaluator.eval("t", value: 0.5) // => 6
evaluator.eval("t", value: 1.0) // => 0
```

The parser will return `nil` if it is unable to completely parse the expression.

By default, the expression parser and evaluator handle the following symbols and functions:

* Constants: `pi` (`π`) and `e`
* 1-argument functions: `sin`, `cos`, `tan`, `log10`, `ln` (`loge`), `log2`, `exp`, `ceil`, `floor`, `round`, `sqrt` (`√`)
* 2-argument functions: `atan`, `hypot`, `pow` [^1]
* alternative math operator symbols: `×` for multiplication and `÷` for division (see example above for use of `×`)

You can reference additional symbols or variables and functions by providing your own mapping functions. There are two
places where this can be done:

* `MathParser.init`
* `MathParser.Evaluator.eval`

If a symbol or function does not exist during an `eval` call, the final result will be `NaN`. If a symbol is resolved
during parsing, it will be replaced with the symbol's value. Otherwise, it will be resolved during a future `eval` call.
Same for function calls -- if the function is known during parsing _and_ all arguments have a known value, then it will
be replaced with the function result. Otherwise, the function call will take place during an `eval` call.

You can get the unresolved symbol names from the `Evaluator.unresolved` attribute. It returns three collections for
unresolved variables, unary functions, and binary function names.

Example:

```swift
let mySymbols = ["foo": 123.4]
let myFuncs: [String:(Double)->Double] = ["twice": {$0 + $0}]
let parser = MathParser(symbols: mySymbols.producer, unaryFunctions: myFuncs.producer)
let myEvalFuncs: [String:(Double)->Double] = ["power": {$0 * $0}]
let evaluator = parser.parse("power(twice(foo))")

# Expression parsed and `twice(foo)` resolved to `246.8` but `power` is still unknown
evaluator?.value // => nan
evaluator?.unresolved.unaryFunctions // => ['power']'
# Give evaluator way to resolve `power(246.8)`
evaluator?.eval(unaryFunctions: myEvalFuncs.producer) // => 60910.240000000005
```

## Implied Multiplication

One of the original goals of this parser was to be able to accept a Wolfram Alpha math expression more or less as-is
-- for instance the definition https://www.wolframalpha.com/input/?i=Sawsbuck+Winter+Form%E2%80%90like+curve -- without
any editing. Here is the start of the textual representation from the above link:

```
x(t) = ((-2/9 sin(11/7 - 4 t) + 78/11 sin(t + 11/7) + 2/7 sin(2 t + 8/5) ...
```

Skipping over the assignment one can readily see that the representation includes implied multiplication between terms
when there are no explicit math operators present (eg `-2/9` __x__ `sin(11/7 - 4` __x__ `t)`). There is support for this
sort of operation in the parser that can be enabled by setting `enableImpliedMultiplication` when creating a new
`MathParser` instance (it defaults to `false`). Note that when enabled, an expression such as `2^3 2^4` would be
considered a valid expression, resolving to `2^3 * 2^4 = 128`, and `4sin(t(pi))` would become `4 * sin(t * pi)`.

You can see the entire Wolfram example in the [TestWolfram](Tests/MathParserTests/TestWolfram.swift) test case.

Here is the original example expression from the start of this README file with implied multiplication in use (all of the muliplication symbols 
have been removed):

```swift
let parser = MathParser(enableImpliedMultiplication: true)
let evaluator = parser.parse("4sin(t π) + 2sin(t π)")
evaluator.eval("t", value: 0.0) // => 0.0
evaluator.eval("t", value: 0.25) // => 4.2426406871192848
evaluator.eval("t", value: 0.5) // => 6
evaluator.eval("t", value: 1.0) // => 0
```

Note that with `enableImpliedMultiplication` enabled, `tπ` will be broken into `t` and `π` even though one could have a
symbol called `tπ`. This eager splitting of a symbol may cause unexpected multiplication. For instance, if you have a 
symbol defined with the name `pin`, this will be split into `pi` and `n` because `pi` / `π` is a known symbol. The best 
way to protect from this happening is to not enable `enabledImpliedMultiplication` but an alternative is to always
separate individual symbols with a space -- or place one inside a pair of parentheses.

[^1]: Redundant since there is already the `^` operator.

