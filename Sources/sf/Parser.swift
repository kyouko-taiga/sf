/// An error that occurred during parsing.
public struct ParseError: Error, CustomStringConvertible {

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

/// The parsing of a source file.
public struct Parser {

  /// The tokens in the input.
  private var tokens: Lexer

  /// The position immediately after the last consumed token.
  private var position: SourceFile.Index

  /// The next token to consume, if already extracted from the source.
  private var lookahead: Token? = nil

  /// Creates an instance parsing `source`.
  private init(_ source: SourceFile) {
    self.tokens = Lexer(tokenizing: source)
    self.position = source.startIndex
  }

  /// Parses a term.
  private mutating func term() throws -> TermSyntax {
    var f = try atom()

    // Accumulate arguments.
    while true {
      // Can we parse an operator?
      if let o = (take(.operator) ?? take(.is)) {
        let a = TermSyntax.init(.variable, at: o.site)
        let s = SourceSpan(region: f.site.start ..< a.site.end, source: f.site.source)
        f = .init(.application(a, f), at: s)

        let b = try atom()
        f = .init(.application(f, b), at: span(from: f.site.start))
      }

      // Can we parse a type application?
      else if take(.at) != nil {
        let t = try type()
        f = .init(.typeApplication(f, t), at: span(from: f.site.start))
      }

      // Can we parse a term application?
      else if let h = peek(), !h.isTerminator {
        // else if let a = attempt({ (me) in try me.atom() }) {
        let a = try atom()
        f = .init(.application(f, a), at: span(from: f.site.start))
      }

      // Nothing more we can parse.
      else { break }
    }

    return f
  }

  /// Parses the head of a term.
  private mutating func atom() throws -> TermSyntax {
    switch peek()?.tag {
    case .unit:
      return .init(.unit, at: take()!.site)
    case .true, .false:
      return .init(.boolean, at: take()!.site)
    case .integerLiteral, .floatingPointLiteral:
      return .init(.number, at: take()!.site)
    case .identifier:
      return .init(.variable, at: take()!.site)
    case .fix:
      return try fix()
    case .fun:
      return try abstraction()
    case .if:
      return try conditional()
    case .let:
      return try binding()
    case .leftBracket:
      return try typeAbstraction()
    case .leftParenthesis:
      return try parenthesized({ (me) in try me.term() })
    default:
      throw expected("term")
    }
  }

  /// Parses a term abstraction.
  private mutating func abstraction() throws -> TermSyntax {
    let s = try expect(.fun)

    // Parameter.
    let x = try expect(.identifier)
    try expect(.colon)
    let t = try type()

    // Body.
    try expect(.assign)
    let b = try term()
    return .init(.abstraction(.init(String(x.text), at: x.site), t, b), at: span(from: s))
  }

  /// Parses a type abstraction.
  private mutating func typeAbstraction() throws -> TermSyntax {
    // Parameter
    let s = try expect(.leftBracket)
    let x = try expect(.identifier)
    try expect(.rightBracket)

    // Body
    let b = try term()
    return .init(.typeAbstraction(.init(String(x.text), at: x.site), b), at: span(from: s))
  }

  /// Parses a let binding.
  private mutating func binding() throws -> TermSyntax {
    let s = try expect(.let)
    let x = try expect(.identifier)
    try expect(.assign)
    let t = try term()
    try expect(.in)
    let u = try term()
    return .init(.binding(.init(String(x.text), at: x.site), t, u), at: span(from: s))
  }

  /// Parses a conditional expression.
  private mutating func conditional() throws -> TermSyntax {
    let s = try expect(.if)
    let c = try term()
    try expect(.then)
    let t = try term()
    try expect(.else)
    let e = try term()
    return .init(.conditional(c, t, e), at: span(from: s))
  }

  /// Parses a recursive term abstraction.
  private mutating func fix() throws -> TermSyntax {
    let s = try expect(.fix)

    // Parameter.
    let x = try expect(.identifier)
    try expect(.colon)
    let t = try type()

    // Body.
    try expect(.in)
    let b = try term()

    return .init(.fix(.init(String(x.text), at: x.site), t, b), at: span(from: s))
  }

  /// Parses a type.
  private mutating func type() throws -> TypeSyntax {
    let t = try typeAtom()
    if take(.arrow) != nil {
      let u = try type()
      return .init(.arrow(t, u), at: span(from: t.site.start))
    } else {
      return t
    }
  }

  /// Parses the head of a type.
  private mutating func typeAtom() throws -> TypeSyntax {
    switch peek()?.tag {
    case .identifier:
      return .init(.identifier, at: take()!.site)
    case .unit:
      return .init(.unit, at: take()!.site)
    case .leftBracket:
      return try forall()
    case .leftParenthesis:
      return try parenthesized({ (me) in try me.type() })
    default:
      throw expected("type")
    }
  }

  /// Parses a universal type.
  private mutating func forall() throws -> TypeSyntax {
    // Parameter
    let s = try expect(.leftBracket)
    let x = try expect(.identifier)
    try expect(.rightBracket)

    // Body
    let b = try type()
    return .init(.forall(.init(String(x.text), at: x.site), b), at: span(from: s))
  }

  /// Returns `true` iff the next token has tag `k`, without consuming that token.
  private mutating func next(is k: Token.Tag) -> Bool {
    peek()?.tag == k
  }

  /// Returns the next token without consuming it.
  private mutating func peek() -> Token? {
    if lookahead == nil { lookahead = tokens.next() }
    return lookahead
  }

  /// Consumes and returns the next token.
  private mutating func take() -> Token? {
    let n = lookahead.take() ?? tokens.next()
    position = n?.site.end ?? tokens.source.endIndex
    return n
  }

  /// Consumes and returns the next token iff it has tag `k`.
  private mutating func take(_ k: Token.Tag) -> Token? {
    next(is: k) ? take() : nil
  }

  /// Parses a token with tag `k`.
  @discardableResult
  private mutating func expect(_ k: Token.Tag) throws -> Token {
    try take(k) ?? expected(Self.describe(k))
  }

  /// Parses an instance of `T` enclosed in parentheses.
  private mutating func parenthesized<T>(_ parse: (inout Self) throws -> T) throws -> T {
    try expect(.leftParenthesis)
    let item = try parse(&self)
    try expect(.rightParenthesis)
    return item
  }

  /// Parses an instance of `T` or returns `nil` if an error occurred while doing it.
  private mutating func attempt<T>(_ parse: (inout Self) throws -> T) -> T? {
    var backup = self
    do {
      return try parse(&self)
    } catch {
      swap(&self, &backup)
      return nil
    }
  }

  /// Returns a source span from `s` to the current position.
  private func span(from s: SourceFile.Index) -> SourceSpan {
    .init(region: s ..< position, source: tokens.source)
  }

  /// Returns a source span from the first position of `t` to the current position.
  private func span(from t: Token) -> SourceSpan {
    .init(region: t.site.start ..< position, source: tokens.source)
  }

  /// Returns a parse error reporting that `s` was expected at `site`.
  private func expected(_ s: String, at site: SourceSpan) -> ParseError {
    .init("expected \(s)", at: site)
  }

  /// Returns a parse error reporting that `s` was expected at the current position.
  private func expected(_ s: String) -> ParseError {
    expected(s, at: .init(region: position ..< position, source: tokens.source))
  }

  /// Returns a description of `t` for error reporting.
  private static func describe(_ t: Token.Tag) -> String {
    switch t {
    case .assign: "'='"
    case .colon: "':'"
    case .leftBracket: "'['"
    case .rightBracket: "']'"
    case .leftParenthesis: "'('"
    case .rightParenthesis: "')'"
    default: "\(self)"
    }
  }

}

extension Parser {

  /// Parses and returns program in `source` and returns its root, inserting trees into `program`.
  public static func parse(_ source: SourceFile) throws -> TermSyntax {
    var p = Parser(source)
    return try p.term()
  }

}
