/// An error that occurred during evaluation.
public struct RuntimeError: Error, CustomStringConvertible {

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

/// A mapping from terms to their value.
public struct RuntimeEnvironment: Sendable {

  /// A mapping from term variable to its value.
  private var mappings: [(String, Value)] = []

  /// Creates an empty environment.
  public init() {}

  /// Returns a copy of `self` in which the term variable `x` maps to the value `v`.
  public func mapping(_ x: String, to v: Value) -> Self {
    var clone = self
    clone.mappings.append((x, v))
    return clone
  }

  /// Returns the value of `x`, if any.
  public subscript(x: String) -> Value? {
    if let (_, v) = mappings.last(where: { (m) in m.0 == x }) {
      return v
    } else {
      return Self.builtin[x]
    }
  }

}

extension TermSyntax {

  /// Returns the evaluation of this term in the environment `e`.
  public func eval(in e: RuntimeEnvironment) throws -> Value {
    switch tag {
    case .unit:
      return .unit

    case .boolean:
      return .boolean(site.text == "true")

    case .number:
      return .number(Double(site.text)!)

    case .variable:
      // Note: type safety guarantees that `self` is in `e`.
      return e[String(site.text)]!

    case .abstraction:
      return .closure(self, e)

    case .application(let x, let y):
      let lambda = try x.lambda(in: e)
      let argument = try y.eval(in: e)
      switch lambda {
      case .user(let captures, let parameter, let body):
        return try body.eval(in: captures.mapping(parameter, to: argument))
      case .builtin(let f):
        return f(argument)
      }

    case .typeAbstraction(_, let t):
      return try t.eval(in: e)

    case .typeApplication(let t, _):
      return try t.eval(in: e)

    case .binding(let p, let x, let y):
      let v = try x.eval(in: e)
      return try y.eval(in: e.mapping(p.value, to: v))

    case .conditional(let x, let y, let z):
      if case .boolean(true) = try x.eval(in: e) {
        return try y.eval(in: e)
      } else {
        return try z.eval(in: e)
      }

    case .fix(let parameter, _, let function):
      return .closure(function, e.mapping(parameter.value, to: .lazy(self)))
    }
  }

  /// Returns the evaluation of `self`, which denotes a closure.
  private func lambda(
    in e: RuntimeEnvironment
  ) throws -> Lambda {
    switch try eval(in: e) {
    case .closure(let function, let captures):
      if case .abstraction(let parameter, _, let body) = function.tag {
        return .user(captures, parameter.value, body)
      } else {
        fatalError("not a function")
      }

    case .lazy(let w):
      return try w.lambda(in: e)

    case .builtin(let f):
      return .builtin(f)

    default:
      fatalError("not a function")
    }
  }

  /// The value of a function.
  private enum Lambda {

    /// A closure represented as an abstraction together with a set of captures.
    ///
    /// Given a payload `(e, x, t)`, the function can be described by the term `λx.t` where `e`
    /// contains the free variables of `t`.
    case user(RuntimeEnvironment, String, TermSyntax)

    /// A built-in function.
    case builtin(@Sendable (Value) -> Value)

  }

}
