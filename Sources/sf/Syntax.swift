/// The expression of a type.
public struct TypeSyntax: Sendable {

  /// The representation of the type.
  public let tag: Tag

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(_ tag: Tag, at site: SourceSpan) {
    self.tag = tag
    self.site = site
  }

  /// The representation of a type.
  public indirect enum Tag: Sendable {

    /// A type identifier.
    case identifier

    /// The unit type.
    case unit

    /// The type of a function.
    case arrow(TypeSyntax, TypeSyntax)

    /// The type of a type abstraction.
    case forall(Parsed<String>, TypeSyntax)

  }

}

extension TypeSyntax: CustomStringConvertible {

  public var description: String {
    switch tag {
    case .arrow(let t, let u):
      return "\(t) -> \(u)"
    case .forall(let t, let u):
      return "[\(t)] \(u)"
    default:
      return String(site.text)
    }
  }

}

/// The expression of a value.
public struct TermSyntax: Sendable {

  /// The representation of the value.
  public let tag: Tag

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(_ tag: Tag, at site: SourceSpan) {
    self.tag = tag
    self.site = site
  }

  /// The representation of a value.
  public indirect enum Tag: Sendable {

    /// A unit value.
    case unit

    /// A Boolean value.
    case boolean

    /// A number.
    case number

    /// A term variable.
    case variable

    /// A term abstraction (i.e., a function).
    case abstraction(Parsed<String>, TypeSyntax, TermSyntax)

    /// A term application.
    case application(TermSyntax, TermSyntax)

    /// A type abstraction.
    case typeAbstraction(Parsed<String>, TermSyntax)

    /// A type application.
    case typeApplication(TermSyntax, TypeSyntax)

    /// A let binding.
    case binding(Parsed<String>, TermSyntax, TermSyntax)

    /// A conditional expression.
    case conditional(TermSyntax, TermSyntax, TermSyntax)

    /// A recursive term abstraction.
    case fix(Parsed<String>, TypeSyntax, TermSyntax)

  }

}

extension TermSyntax: CustomStringConvertible {

  public var description: String {
    switch tag {
    case .abstraction(let p, let t, let x):
      return "(fun \(p) : \(t) = \(x))"
    case .application(let x, let y):
      return "(\(x) \(y))"
    case .typeAbstraction(let t, let x):
      return "[\(t)] \(x)"
    case .typeApplication(let x, let t):
      return "\(x) @\(t)"
    case .binding(let p, let x, let y):
      return "let \(p) = \(x) in \(y)"
    case .conditional(let x, let y, let z):
      return "if \(x) then \(y) else \(z)"
    case .fix(let p, let t, let x):
      return "(fix \(p) : \(t) in \(x))"
    default:
      return String(site.text)
    }
  }

}

/// A construct whose representation was parsed from a source files.
public struct Parsed<T> {

  /// The parsed construct.
  public let value: T

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance annotating its value with the site from which it was extracted.
  public init(_ value: T, at site: SourceSpan) {
    self.value = value
    self.site = site
  }

}

extension Parsed: Sendable where T: Sendable {}

extension Parsed: CustomStringConvertible {

  public var description: String {
    String(describing: value)
  }

}
