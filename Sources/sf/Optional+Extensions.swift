extension Optional {

  /// Returns the value wrapped in `self` or throws `error` if `self` is `nil`.
  public func unwrapOrThrow<E: Error>(_ error: @autoclosure () -> E) throws -> Wrapped {
    if let wrapped = self { wrapped } else { throw error() }
  }

  /// Returns the value wrapped in `optional` or throws `error` if `optional` is `nil`.
  public static func ?? <E: Error>(optional: Self, error: @autoclosure () -> E) throws -> Wrapped {
    try optional.unwrapOrThrow(error())
  }

  /// Returns the value wrapped in `optional` or calls `trap` if `optional` is `nil`.
  public static func ?? (optional: Self, trap: @autoclosure () -> Never) -> Wrapped {
    if let wrapped = optional { wrapped } else { trap() }
  }

}
