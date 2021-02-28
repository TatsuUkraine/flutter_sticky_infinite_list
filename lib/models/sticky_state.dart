/// Sticky state object
/// that describes header position and content height
class StickyState<I> {
  /// Position, that header already passed
  ///
  /// Value can be between 0.0 and 1.0
  ///
  /// If it's `0.0` - sticky in max start position
  ///
  /// `1.0` - max end position
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true with [InfiniteListItem.overlay],
  /// or default [InfiniteListItem] constructor is used,
  /// initial header render will be with position = 0
  final double position;

  /// Number of pixels, that outside of viewport
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true with [InfiniteListItem.overlay],
  /// or default [InfiniteListItem] constructor is used,
  /// header render will be with offset = 0
  ///
  /// For header bottom positions (or right positions for horizontal)
  /// offset value also will be amount of pixels that was scrolled away
  final double offset;

  /// Item index
  final I index;

  /// If header is in sticky state
  ///
  /// If [InfiniteListItem.minOffsetProvider] is defined,
  /// it could be that header builder will be emitted with new state
  /// on scroll, but [sticky] will be false, if offset already passed
  /// min offset value
  ///
  /// WHen [InfiniteListItem.minOffsetProvider] is called, [sticky]
  /// will always be `false`. Since for min offset calculation
  /// offset itself not defined yet
  final bool sticky;

  /// Scroll item height.
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true with [InfiniteListItem.overlay],
  /// or default [InfiniteListItem] constructor is used,
  /// initial header render will be called without this value
  final double? contentSize;

  StickyState(this.index,
      {this.position = 0,
      this.offset = 0,
      this.sticky = false,
      this.contentSize});

  /// Create state duplicate, with optional state options override
  StickyState<I> copyWith(
          {double? position,
          double? offset,
          bool? sticky,
          double? contentHeight}) =>
      StickyState<I>(
        index,
        position: position ?? this.position,
        offset: offset ?? this.offset,
        sticky: sticky ?? this.sticky,
        contentSize: contentHeight ?? this.contentSize,
      );
}
