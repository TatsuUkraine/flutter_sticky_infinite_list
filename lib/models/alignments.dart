/// Header position axis for content without header overflow
enum HeaderPositionAxis {
  /// Align against main axis direction
  mainAxis,

  /// Align against cross axis direction
  crossAxis,
}

/// Main axis direction alignment
enum HeaderMainAxisAlignment {
  /// Start position against main axis
  ///
  /// For Horizontal scroll header will be places at the left,
  /// for vertical - at the top side
  start,

  /// End alignment
  ///
  /// For Horizontal scroll header will be places at the right,
  /// for vertical - at the bottom side
  end,
}

/// Cross axis header alignment
enum HeaderCrossAxisAlignment {
  /// Start position against cross axis
  ///
  /// For Horizontal scroll header will be places at top,
  /// for vertical - at the left side
  start,

  /// Center position against cross axis
  ///
  /// This value can be used only with overlay headers,
  /// or with relative header and [HeaderPositionAxis.mainAxis]
  center,

  /// End position against cross axis
  ///
  /// For Horizontal scroll header will be places at the bottom,
  /// for vertical - at the right side
  end,
}

enum InfiniteListDirection {
  /// Render only positive infinite list
  single,

  /// Render both positive and negative infinite lists
  multi,
}