import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import './state.dart';
import './render.dart';

typedef InfiniteListItem<I> ItemBuilder<I>(BuildContext context, I index);

/// List item build should return instance on this class
///
/// It can be overriden if needed
///
/// This class build item header and content
class InfiniteListItem<I> {
  final HeaderStateBuilder<I> headerStateBuilder;
  final HeaderBuilder headerBuilder;
  final ContentBuilder contentBuilder;

  /// Function, that provides min offset.
  ///
  /// If Visible content offset if less than provided value
  /// Header will be stick to bottom
  ///
  /// By default header positioned until it's offset less than content height
  final MinOffsetProvider<I> minOffsetProvider;

  InfiniteListItem({
    @required this.contentBuilder,
    this.headerBuilder,
    this.headerStateBuilder,
    this.minOffsetProvider,
  });

  bool get hasStickyHeader => headerBuilder != null || headerStateBuilder != null;

  bool get watchStickyState => headerStateBuilder != null;

  /// Header item builder
  /// Receives [BuildContext] and [StickyState]
  ///
  /// If [headerBuilder] and [headerStateBuilder] not specified, this method won't be called
  ///
  /// Second param [StickyState] will be passed if [watchStickyState] is `TRUE`
  Widget buildHeader(BuildContext context, [StickyState<I> state]) {
    if (state == null) {
      return headerBuilder(context);
    }

    return headerStateBuilder(context, state);
  }

  /// Content item builder
  Widget buildContent(BuildContext context) => contentBuilder(context);

  /// Called during init state (see [State.initState])
  @protected
  @mustCallSuper
  void initState() {}

  /// Called whenever item is destroyed (see [State.dispose] lifecycle)
  /// If this method is override, [dispose] should called
  @protected
  @mustCallSuper
  void dispose() {}

  Widget _getHeader(BuildContext context, Stream<StickyState<I>> stream) {
    assert(hasStickyHeader, "At least one builder should be provided");

    if (!watchStickyState) {
      return buildHeader(context);
    }

    return Positioned(
      child: StreamBuilder<StickyState<I>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }

          return buildHeader(context, snapshot.data);
        },
      ),
    );
  }
}

/// Scrollable list
///
/// This widget renders [CustomScrollView] with 2 sliver list items
///
/// If [direction] is [InfiniteListDirection.single] it will render only forward
/// sliver list item without center key
///
/// If [direction] is [InfiniteListDirection.multi] - both direction infinite list will be rendered
class InfiniteList extends StatefulWidget {
  /// Builder callback. It should return [InfiniteListItem] instance.
  ///
  /// This function is called during [SliverChildBuilderDelegate]
  final ItemBuilder<int> builder;

  /// Scroll controller
  final ScrollController controller;

  /// List direction
  ///
  /// By default [InfiniteListDirection.single]
  ///
  /// If [InfiniteListDirection.multi] is passed - will render infinite list in both directions
  final InfiniteListDirection direction;

  /// Max child count for positive direction list
  final int maxChildCount;

  /// Max child count for negative list direction
  ///
  /// Ignored when [direction] is [InfiniteListDirection.single]
  ///
  /// This value should have negative value in order to provide right calculation
  /// for negative list
  final int minChildCount;

  /// Scroll direction
  ///
  /// Passes to [CustomScrollView.reverse]
  final bool reverse = false;
  final Key _centerKey;

  InfiniteList({
    Key key,
    @required this.builder,
    this.controller,
    this.direction = InfiniteListDirection.single,
    this.maxChildCount,
    this.minChildCount,
    /// commented out for future improvement
    //this.reverse = false,
  }): _centerKey = (direction == InfiniteListDirection.multi) ? UniqueKey() : null,
      super(key: key);

  @override
  State<StatefulWidget> createState() => _InfiniteListState();

}

class _InfiniteListState extends State<InfiniteList> {
  StreamController<StickyState> _streamController = StreamController<StickyState<int>>.broadcast();

  int get _reverseChildCount => widget.minChildCount == null ? null : widget.minChildCount * -1;

  SliverList get _reverseList => SliverList(
    delegate: SliverChildBuilderDelegate(
      (BuildContext context, int index) => _getListItem(context, (index + 1) * -1),
      childCount: _reverseChildCount,
    ),
  );

  SliverList get _forwardList => SliverList(
    delegate: SliverChildBuilderDelegate(
      _getListItem,
      childCount: widget.maxChildCount,
    ),
    key: widget._centerKey,
  );

  Widget _getListItem(BuildContext context, int index) => _StickySliverListItem<int>(
    streamController: _streamController,
    index: index,
    listItem: widget.builder(context, index),
  );

  List<SliverList> get _slivers {
    switch (widget.direction) {
      case InfiniteListDirection.multi:
        return [
          _reverseList,
          _forwardList,
        ];

      case InfiniteListDirection.single:
      default:
        return [
          _forwardList,
        ];
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: widget.controller,
    center: widget._centerKey,
    slivers: _slivers,
    reverse: widget.reverse
  );

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();

    _streamController.close();
  }
}


class _StickySliverListItem<I> extends StatefulWidget {
  final InfiniteListItem<I> listItem;
  final I index;
  final StreamController<StickyState<I>> streamController;

  Stream<StickyState<I>> get _stream => streamController.stream.where((state) => state.index == index);

  _StickySliverListItem({
    Key key,
    this.index,
    this.listItem,
    this.streamController,
  }): super(key: key);

  @override
  State<_StickySliverListItem<I>> createState() => _StickySliverListItemState<I>();
}

class _StickySliverListItemState<I> extends State<_StickySliverListItem<I>> {

  @override
  void initState() {
    super.initState();

    widget.listItem.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = widget.listItem.buildContent(context);

    if (!widget.listItem.hasStickyHeader) {
      return content;
    }

    return StickyListItem<I>(
      itemIndex: widget.index,
      streamSink: widget.streamController.sink,
      header: widget.listItem._getHeader(context, widget._stream),
      content: content,
      minOffsetProvider: widget.listItem.minOffsetProvider,
    );
  }

  @override
  void dispose() {
    super.dispose();

    widget.listItem.dispose();
  }

}

/// Sticky list item that provides header offset calculation
///
/// Max and min offset value are defined based on content height
///
/// Can be used separately from [InfiniteList] if needed
class StickyListItem<I> extends Stack {
  /// Stream sink object
  ///
  /// If provided - render object will emit event on each header offset change
  final StreamSink<StickyState<I>> streamSink;

  /// Value that will be used inside [StickyState] object
  /// during stream event emit
  final I itemIndex;

  /// Callback function that tells when header to stick to the bottom
  final MinOffsetProvider<I> minOffsetProvider;

  final bool reverse;

  StickyListItem({
    @required Widget header,
    @required Widget content,
    @required this.itemIndex,
    this.minOffsetProvider,
    this.streamSink,
    this.reverse,
    Key key,
  }): super(
    key: key,
    children: [content, header],
    alignment: AlignmentDirectional.topStart,
    overflow: Overflow.clip,
  );

  ScrollableState _getScrollableState(BuildContext context) => Scrollable.of(context);

  @override
  RenderStack createRenderObject(BuildContext context) => StickyListItemRenderObject<I>(
    scrollable: _getScrollableState(context),
    alignment: alignment,
    textDirection: textDirection ?? Directionality.of(context),
    fit: fit,
    overflow: overflow,
    itemIndex: itemIndex,
    streamSink: streamSink,
    minOffsetProvider: minOffsetProvider,
    reverse: reverse,
  );

  @override
  @mustCallSuper
  void updateRenderObject(BuildContext context, StickyListItemRenderObject<I> renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject
      ..scrollable = _getScrollableState(context)
      ..itemIndex = itemIndex
      ..streamSink = streamSink
      ..minOffsetProvider = minOffsetProvider
      ..reverse = reverse;
  }
}