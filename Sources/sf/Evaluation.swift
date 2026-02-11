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
  ///
  /// This method implements the runtime semantics of `sf` in the form of an interpreter, defined
  /// as a function from well-typed terms to values.
  ///
  /// Note that no type information is taken into account to compute the results of this method.
  /// However, well-typedness guarantees freedom from a number of errors, which explains why the
  /// method cannot throw. Execution may trap at runtime nonetheless due to an illegal operation
  /// not caught by the static semantics of `sf` (e.g., division by 0).
  ///
  /// - Precondition `self` is well-typed.
  public func eval(in e: RuntimeEnvironment) -> Value {
    switch tag {
    case .unit:
      return .unit

    case .boolean:
      return .boolean(site.text == "true")

    case .number:
      return .number(Double(site.text)!)

    case .variable:
      return e[String(site.text)]!

    case .abstraction:
      return .closure(self, e)

    case .application(let x, let y):
      let lambda = x.lambda(in: e)
      let argument = y.eval(in: e)
      switch lambda {
      case .user(let captures, let parameter, let body):
        return body.eval(in: captures.mapping(parameter, to: argument))
      case .builtin(let f):
        return f(argument)
      }

    case .typeAbstraction(_, let t):
      return t.eval(in: e)

    case .typeApplication(let t, _):
      return t.eval(in: e)

    case .binding(let p, let x, let y):
      let v = x.eval(in: e)
      return y.eval(in: e.mapping(p.value, to: v))

    case .conditional(let x, let y, let z):
      if case .boolean(true) = x.eval(in: e) {
        return y.eval(in: e)
      } else {
        return z.eval(in: e)
      }

    case .fix(let parameter, _, let function):
      return .closure(function, e.mapping(parameter.value, to: .lazy(self)))
    }
  }

  /// Returns the evaluation of `self`, which denotes a closure.
  ///
  /// This method is called in the handling of term applications to evaluate the callable entity
  /// expressed by a term. Three cases are possible:
  ///
  /// * `self` denotes an ordinary term abstraction, in which case the resulting value is a closure
  ///   capturing the run-time environment `e`.
  /// * `self` denotes a recursive term abstraction, in which case the resulting value "unrolls"
  ///   one instance from the recursively definition of the abstraction.
  /// * `self` denotes a built-in function which is simply wrapped into the resulting value.
  private func lambda(in e: RuntimeEnvironment) -> Callable {
    switch eval(in: e) {
    case .closure(let function, let captures):
      if case .abstraction(let parameter, _, let body) = function.tag {
        return .user(captures, parameter.value, body)
      } else {
        fatalError("not a function")
      }

    case .lazy(let w):
      return w.lambda(in: e)

    case .builtin(let f):
      return .builtin(f)

    default:
      fatalError("not a function")
    }
  }

  /// The value of a callable entity.
  private enum Callable {

    /// A closure represented as an abstraction together with a set of captures.
    ///
    /// Given a payload `(e, x, t)`, the function can be described by the term `λx.t` where `e`
    /// contains the free variables of `t`.
    case user(RuntimeEnvironment, String, TermSyntax)

    /// A built-in function.
    case builtin(@Sendable (Value) -> Value)

  }

}
