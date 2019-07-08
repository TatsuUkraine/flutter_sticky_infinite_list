import 'package:flutter/widgets.dart';

typedef Widget ContentBuilder(BuildContext context);
typedef Widget HeaderStateBuilder(BuildContext context, StickyState state);
typedef Widget HeaderBuilder(BuildContext context);
typedef double MinOffsetProvider(StickyState state);

enum InfiniteListDirection {
  forward,
  reverse,
  multi,
}

class StickyState {
  final double position;
  final double offset;
  final int index;
  final bool sticky;
  final double contentHeight;

  StickyState(this.index, {
    this.position = 0,
    this.offset = 0,
    this.sticky = false,
    this.contentHeight
  });

  StickyState copyWith({
    double position,
    double offset,
    bool sticky,
    double contentHeight
  }) => StickyState(
    index,
    position: position ?? this.position,
    offset: offset ?? this.offset,
    sticky: sticky ?? this.sticky,
    contentHeight: contentHeight ?? this.contentHeight,
  );
}
