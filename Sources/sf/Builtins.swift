extension TypingEnvironment {

  /// The types of built-in symbols.
  static let builtin: [String: TypeTree] = [
    // Boolean operators.
    "is" : .arrow(.boolean, .arrow(.boolean, .boolean)),
    "not": .arrow(.boolean, .boolean),

    // Comparison operators.
    "<"  : .arrow(.number, .arrow(.number, .boolean)),
    "<=" : .arrow(.number, .arrow(.number, .boolean)),
    ">"  : .arrow(.number, .arrow(.number, .boolean)),
    ">=" : .arrow(.number, .arrow(.number, .boolean)),
    "==" : .arrow(.number, .arrow(.number, .boolean)),
    "!=" : .arrow(.number, .arrow(.number, .boolean)),

    // Arithmetic operators.
    "+"  : .arrow(.number, .arrow(.number, .number)),
    "-"  : .arrow(.number, .arrow(.number, .number)),
    "*"  : .arrow(.number, .arrow(.number, .number)),
    "/"  : .arrow(.number, .arrow(.number, .number)),
  ]

}

extension RuntimeEnvironment {

  /// The values of built-in symbols.
  static let builtin: [String: Value] = [
    // Boolean operators.
    "is" : curry({ (a, b) in .boolean(a.boolean! == b.boolean!) }),
    "not": .builtin({ (a) in .boolean(!a.boolean!) }),

    // Comparison operators.
    "<"  : curry({ (a, b) in .boolean(a.number! < b.number!) }),
    "<=" : curry({ (a, b) in .boolean(a.number! <= b.number!) }),
    ">"  : curry({ (a, b) in .boolean(a.number! > b.number!) }),
    ">=" : curry({ (a, b) in .boolean(a.number! >= b.number!) }),
    "==" : curry({ (a, b) in .boolean(a.number! == b.number!) }),
    "!=" : curry({ (a, b) in .boolean(a.number! != b.number!) }),

    // Arithmetic operators.
    "+"  : curry({ (a, b) in .number(a.number! + b.number!) }),
    "-"  : curry({ (a, b) in .number(a.number! - b.number!) }),
    "*"  : curry({ (a, b) in .number(a.number! * b.number!) }),
    "/"  : curry({ (a, b) in .number(a.number! / b.number!) }),
  ]

  /// Returns the curried form of `apply`.
  private static func curry(
    _ apply: @escaping @Sendable (Value, Value) -> Value
  ) -> Value {
    .builtin { (a: Value) -> Value in
      .builtin { (b: Value) -> Value in apply(a, b) }
    }
  }

}
