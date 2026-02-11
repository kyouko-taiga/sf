/// A source file.
public typealias SourceFile = String

/// A half-open range of textual positions in a source file.
public struct SourceSpan: Hashable, Sendable {

  /// The bounds of the region that `self` represents.
  public let region: Range<SourceFile.Index>

  /// The source file containing the region that `self` represents.
  public let source: SourceFile

  /// The source text covered by this span.
  public var text: Substring {
    source[region]
  }

  /// The start of the region that `self` represents.
  public var start: SourceFile.Index {
    region.lowerBound
  }

  /// The "past-the-end" position of the region that `self` represents.
  public var end: SourceFile.Index {
    region.upperBound
  }

}
