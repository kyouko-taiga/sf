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
