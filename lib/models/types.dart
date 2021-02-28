import 'package:flutter/widgets.dart';

import 'sticky_state.dart';

typedef ContentBuilder = Widget Function(BuildContext context);
typedef HeaderStateBuilder<I> = Widget Function(
    BuildContext context, StickyState<I> state);
typedef HeaderBuilder = Widget Function(BuildContext context);
typedef MinOffsetProvider<I> = double? Function(StickyState<I> state);
