import 'package:flutter/widgets.dart';

typedef Widget ContentBuilder(BuildContext context);
typedef Widget HeaderStateBuilder<I>(
    BuildContext context, StickyState<I> state);
typedef Widget HeaderBuilder(BuildContext context);
typedef double MinOffsetProvider<I>(StickyState<I> state);

enum InfiniteListDirection {
  single,
  multi,
}

class StickyState<I> {
  final double position;
  final double offset;
  final I index;
  final bool sticky;
  final double contentHeight;

  StickyState(this.index, {
    this.position = 0,
    this.offset = 0,
    this.sticky = false,
    this.contentHeight
  });

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
    contentHeight: contentHeight ?? this.contentHeight,
  );
}
