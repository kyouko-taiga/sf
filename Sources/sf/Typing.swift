/// An error that occurred during typing.
public struct TypeError: Error, CustomStringConvertible {

  /// A description of the error that occurred.
  public let description: String

  /// The source code or source position (if empty) identified as the cause of the error.
  public let site: SourceSpan

  /// Creates an instance reporting `problem` at `site`.
  public init(_ problem: String, at site: SourceSpan) {
    self.description = problem
    self.site = site
  }

}

/// A mapping from term variables to their types along with a set of type variables.
public struct TypingEnvironment {

  /// A mapping from term variable to its type.
  private var mappings: [(String, TypeTree)] = []

  /// The type variables in scope.
  public private(set) var types: [String] = []

  /// Creates an empty environment.
  public init() {}

  /// Returns a copy of `self` in which the term variable `x` maps to the type `t`.
  public func mapping(_ x: String, to t: TypeTree) -> Self {
    var clone = self
    clone.mappings.append((x, t))
    return clone
  }

  /// Returns a copy of `self` in which the type variable `t` is defined.
  public func adding(_ t: String) -> Self {
    var clone = self
    clone.types.append(t)
    return clone
  }

  /// Returns the type of `x`, if any.
  public subscript(x: String) -> TypeTree? {
    if let (_, v) = mappings.last(where: { (m) in m.0 == x }) {
      return v
    } else {
      return Self.builtin[x]
    }
  }

}

extension TypeSyntax {

  /// Returns the type denoted by `self` in the environment `e`.
  public func denotation(in e: TypingEnvironment) throws -> TypeTree {
    switch tag {
    case .unit:
      return .unit
    case .identifier:
      return try Self.denotation(of: site.text, at: site, in: e)
    case .arrow(let t, let u):
      return try .arrow(t.denotation(in: e), u.denotation(in: e))
    case .forall(let t, let u):
      return try .forall(t.value, u.denotation(in: e.adding(t.value)))
    }
  }

  /// Returns the type dented by `n` in the environment `e`, reporting errors at `s`.
  private static func denotation(
    of n: Substring, at s: SourceSpan, in e: TypingEnvironment
  ) throws -> TypeTree {
    switch n {
    case "Bool":
      return .boolean

    case "Num":
      return .number

    default:
      if e.types.contains(where: { (v) in v == n }) {
        return .variable(String(n))
      } else {
        throw TypeError("undefined type '\(n)'", at: s)
      }

    }
  }

  /// Returns a type error with the specified message.
  private func error(_ problem: String) -> TypeError {
    .init(problem, at: site)
  }

}

extension TermSyntax {

  /// Returns the type of `self` in the environment `e`.
  public func type(in e: TypingEnvironment) throws -> TypeTree {
    switch tag {
    case .unit:
      return .unit

    case .boolean:
      return .boolean

    case .number:
      return .number

    case .variable:
      return try e[String(site.text)] ?? error("undefined symbol '\(site.text)'")

    case .abstraction(let p, let t, let x):
      let a = try t.denotation(in: e)
      let b = try x.type(in: e.mapping(p.value, to: a))
      return try .arrow(a, b)

    case .application(let x, let y):
      switch try x.type(in: e) {
      case .arrow(let a, let b):
        let c = try y.type(in: e)
        if a.isEquivalent(c) {
          return b
        } else {
          throw TypeError("expected '\(a)', found '\(c)'", at: y.site)
        }
      case let a:
        throw TypeError("value of type '\(a)' is not a function", at: x.site)
      }

    case .typeAbstraction(let t, let x):
      return .forall(t.value, try x.type(in: e.adding(t.value)))

    case .typeApplication(let x, let t):
      switch try x.type(in: e) {
      case .forall(let u, let v):
        let b = try t.denotation(in: e)
        return v.substituting(u, for: b)
      case let a:
        throw TypeError("value of type '\(a)' is not a type application", at: x.site)
      }

    case .binding(let p, let x, let y):
      let t = try x.type(in: e)
      return try y.type(in: e.mapping(p.value, to: t))

    case .conditional(let x, let y, let z):
      let a = try x.type(in: e)
      let b = try y.type(in: e)
      let c = try z.type(in: e)
      if a != .boolean {
        throw TypeError("expected 'Bool', found '\(a)'", at: x.site)
      } else if !b.isEquivalent(c) {
        throw TypeError("expected '\(b)', found '\(c)'", at: z.site)
      } else {
        return b
      }

    case .fix(let p, let t, let x):
      switch try t.denotation(in: e) {
      case .arrow(let a, let b):
        let f = TypeTree.arrow(a, b)
        let g = try x.type(in: e.mapping(p.value, to: f))
        if f == g {
          return f
        } else {
          throw TypeError("expected '\(f)', found '\(g)' ", at: t.site)
        }
      case let a:
        throw TypeError("expected arrow type, found '\(a)' ", at: t.site)
      }
    }
  }

  /// Returns a type error with the specified message.
  private func error(_ problem: String) -> TypeError {
    .init(problem, at: site)
  }

}
