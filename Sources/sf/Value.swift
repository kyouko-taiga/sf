/// The result of evaluating a term.
public enum Value: Sendable {

  /// A unit value.
  case unit

  /// A Boolean value.
  case boolean(Bool)

  /// A number.
  case number(Double)

  /// A lambda together with an environment.
  case closure(TermSyntax, RuntimeEnvironment)

  /// A recursive function.
  case lazy(TermSyntax)

  /// A built-in function.
  case builtin(@Sendable (Value) -> Value)

  /// The payload of `self` if it is a Boolean value.
  var boolean: Bool? {
    if case .boolean(let v) = self { v } else { nil }
  }

  /// The payload of `self` if it is a number.
  var number: Double? {
    if case .number(let v) = self { v } else { nil }
  }

}

extension Value: CustomStringConvertible {

  public var description: String {
    switch self {
    case .unit:
      return "unit"
    case .boolean(let v):
      return v.description
    case .number(let v):
      return v.description
    case .closure, .lazy:
      return "$fun"
    case .builtin:
      return "$builtin"
    }
  }

}
