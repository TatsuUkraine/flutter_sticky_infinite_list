import 'package:flutter/widgets.dart';

typedef Widget ContentBuilder(BuildContext context);
typedef Widget HeaderStateBuilder<I>(
    BuildContext context, StickyState<I> state);
typedef Widget HeaderBuilder(BuildContext context);
typedef double MinOffsetProvider<I>(StickyState<I> state);

/// List direction variants
enum InfiniteListDirection {
  /// Render only positive infinite list
  single,

  /// Render both positive and negative infinite lists
  multi,
}

/// Alignment options
///
/// [HeaderAlignment.bottomLeft], [HeaderAlignment.bottomRight] and
/// [HeaderAlignment.bottomCenter] header will be positioned
/// against content bottom edge for vertical scroll
///
/// [HeaderAlignment.topRight], [HeaderAlignment.bottomRight] and
/// [HeaderAlignment.canterRight] header will be positioned
/// against content right edge for horizontal scroll
///
/// Which also means that headers will become sticky, when content
/// bottom edge (or right edge for horizontal) will
/// go outside of ViewPort bottom (right for horizontal) edge
///
/// It also affects on [StickyState.offset] value, since in that case
/// hidden size will be calculated against bottom edges
enum HeaderAlignment {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  centerLeft,
  centerRight,
}

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
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
  /// header render will be with position = 0
  final double position;

  /// Number of pixels, that outside of viewport
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
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
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
  /// header render will be called without this value
  final double contentSize;

  StickyState(this.index, {
    this.position = 0,
    this.offset = 0,
    this.sticky = false,
    this.contentSize
  });

  /// Create state duplicate, with optional state options override
  StickyState<I> copyWith({
    double position,
    double offset,
    bool sticky,
    double contentHeight
  }) => StickyState<I>(
    index,
    position: position ?? this.position,
    offset: offset ?? this.offset,
    sticky: sticky ?? this.sticky,
    contentSize: contentHeight ?? this.contentSize,
  );
}
