import 'package:flutter/widgets.dart';

import 'sticky_state.dart';

typedef Widget ContentBuilder(BuildContext context);
typedef Widget HeaderStateBuilder<I>(BuildContext context, StickyState<I> state);
typedef Widget HeaderBuilder(BuildContext context);
typedef double MinOffsetProvider<I>(StickyState<I> state);
