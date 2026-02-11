# `sf`

 `sf` is a toy implementation of [System F](https://en.wikipedia.org/wiki/System_F), also known as the polymorphic lambda calculus.

**Disclaimer**:
The code in this repository does not, nor intend to, show a particularly efficient implementation of System F.
It is intended to be used as educational material for learning about the general anatomy of type interpreters.

## Installation

This project is written in [Swift](https://www.swift.org) and distributed in the form of a package for [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/).

Assuming Swift is installed on your system, use the following commands to build and run `sf`:

```bash
swift build -c release
.build/release/sf -h
```

The first command compiles `sf` from sources and the second displays usage instructions.

## Features

`sf` implements System F with extended with built-in Boolean and numeric values, along with a few simple syntactic sugars.
Boolean values are either `true` or `false` and have type `Bool`.
Numeric values are represented as double-precision floating point numbers and have type `Num`.
They can be compared and they support simple arithmetic operations.
The following snippet illustrates:

```sf
let factorial =
  fix f : Num -> Num in
    fun n : Num =
      if n < 2 then 1 else n * (f (n - 1))
in factorial(5)
```

See [Sources/sf/Builtins.swift](Builtins.swift) for an exhaustive list of built-in operations.

## Grammar

The complete grammar of `sf` is described below:

```ebnf
type ::=
  | 'unit' | identifier
  | type '->' type
  | '[' identifier ']' type

term ::=
  | 'unit' | 'true' | 'false' | number | identifier
  | 'fun' identifier ':' type '=' term
  | term term
  | '[' identifier ']' term
  | term '@' type
  | 'let' identifier '=' term 'in' term
  | 'if' term 'then' term 'else' term
  | 'fix' identifier ':' type 'in' term
```
