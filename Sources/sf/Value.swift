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
  ///
  /// The tag of the payload is a recursive term abstraction expressed with `TermSyntax.Tag.fix`.
  /// During evaluation, this value expands to a closure mapping the name of recursive definition
  /// to a copy of this value, in the style of Reynold's letrec formalization (see *Theories of
  /// programming languages*. Cambridge University Press, 1998).
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
