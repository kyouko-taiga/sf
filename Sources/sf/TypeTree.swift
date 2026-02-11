/// The type of a term.
public indirect enum TypeTree: Equatable, Sendable {

  /// The unit type.
  case unit

  /// The type of Boolean values.
  case boolean

  /// The type of numbers.
  case number

  /// The type of a function.
  case arrow(TypeTree, TypeTree)

  /// The type of a type abstraction.
  case forall(String, TypeTree)

  /// A type variable.
  case variable(String)

  /// Returns `self` in which occurrences of the variable `x` have been susbtituted for `v`.
  public func substituting(_ x: String, for v: TypeTree) -> TypeTree {
    switch self {
    case .arrow(let t, let u):
      return .arrow(t.substituting(x, for: v), u.substituting(x, for: v))
    case .forall(let y, let t) where x != y:
      return .forall(y, t.substituting(x, for: v))
    case .variable(x):
      return v
    case let t:
      return t
    }
  }

  /// Returns `true` iff `self` is equal to `other` up to some renaming of bound variables.
  ///
  /// This method implements a more relaxed form of equality which abstracts over irrelevant name
  /// over irrelevant name choices. For example, while `[a] a` is not equal to `[b] b`, both types
  /// are equivalent under alpha renaming.
  public func isEquivalent(_ other: TypeTree) -> Bool {
    switch (self, other) {
    case (.arrow(let a0, let b0), .arrow(let a1, let b1)):
      return a0.isEquivalent(a1) && b0.isEquivalent(b1)

    case (.forall(let x0, let t0), .forall(let x1, let t1)):
      if x0 == x1 {
        return t0.isEquivalent(t1)
      } else {
        return t0.isEquivalent(t1.substituting(x1, for: .variable(x0)))
      }

    default:
      return self == other
    }
  }

}

extension TypeTree: CustomStringConvertible {

  public var description: String {
    switch self {
    case .unit:
      return "unit"
    case .boolean:
      return "Bool"
    case .number:
      return "Num"
    case .arrow(let t, let u):
      return "\(t) -> \(u)"
    case .forall(let t, let u):
      return "[\(t)] \(u)"
    case .variable(let t):
      return t
    }
  }

}
