/// A terminal symbol of the syntactic grammar.
public struct Token: Hashable, Sendable {

  /// The tag of a token.
  public enum Tag: UInt8, Sendable {

    // Identifiers
    case identifier
    case underscore

    // Reserved keywords
    case `false`
    case `else`
    case fix
    case fun
    case `if`
    case `in`
    case `is`
    case `let`
    case then
    case `true`
    case unit

    // Scalar literals
    case integerLiteral
    case floatingPointLiteral
    case stringLiteral

    // Operators
    case arrow
    case assign
    case `operator`

    // Punctuation
    case at
    case comma
    case dot
    case colon
    case semicolon

    // Delimiters
    case leftBracket
    case rightBracket
    case leftParenthesis
    case rightParenthesis

    // Errors
    case error
    case unterminatedBlockComment
    case unterminatedStringLiteral

  }

  /// The tag of the token.
  public let tag: Tag

  /// The site from which `self` was extracted.
  public let site: SourceSpan

  /// Creates an instance with the given properties.
  public init(tag: Tag, site: SourceSpan) {
    self.tag = tag
    self.site = site
  }

  /// The text of this token.
  public var text: Substring {
    site.text
  }

  /// Returns `true` iff `self` signals the end of an expression.
  public var isTerminator: Bool {
    switch tag {
    case .assign, .in, .then, .else, .rightBracket, .rightParenthesis:
      return true
    default:
      return false
    }
  }

  /// Returns a lambda accepting a token and returning `true` iff that token has tag `tag`.
  public static func hasTag(_ tag: Tag) -> (Token) -> Bool {
    { (t) in t.tag == tag }
  }

}
