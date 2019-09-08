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

  /// Header alignment
  ///
  /// By default [HeaderAlignment.topLeft]
  ///
  /// For more option take a look in [HeaderAlignment]
  final HeaderAlignment headerAlignment;

  /// Function, that provides min offset.
  ///
  /// If Visible content offset if less than provided value
  /// Header will be stick to bottom
  ///
  /// By default header positioned until it's offset less than content height
  final MinOffsetProvider<I> minOffsetProvider;

  /// If builder should render header
  /// during first run
  ///
  /// To perform accurate header build, by default
  /// it renders after first paint is finished, when
  /// [headerStateBuilder] is defined.
  ///
  /// In some cases it can lead to header render delay.
  ///
  /// To prevent this you can set [initialHeaderBuild] to `true`.
  ///
  /// In that case header will be rendered during initial render
  /// with basic [StickyState] object.
  ///
  /// It will add additional header renderer call.
  ///
  /// If this value is `false` - header render callback will be called
  /// only after it's parent and content will be laid out.
  ///
  /// For case when only [headerBuilder] is defined,
  /// this property will be ignored
  final bool initialHeaderBuild;

  InfiniteListItem({
    @required this.contentBuilder,
    this.headerBuilder,
    this.headerStateBuilder,
    this.minOffsetProvider,
    this.headerAlignment = HeaderAlignment.topLeft,
    this.initialHeaderBuild = false,
  });

  bool get hasStickyHeader =>
      headerBuilder != null || headerStateBuilder != null;

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

  Widget _getHeader(BuildContext context, Stream<StickyState<I>> stream, I index) {
    assert(hasStickyHeader, "At least one builder should be provided");

    if (!watchStickyState) {
      return buildHeader(context);
    }

    return Positioned(
      child: StreamBuilder<StickyState<I>>(
        stream: stream,
        initialData: initialHeaderBuild ? StickyState<I>(index) : null,
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
  /// If [InfiniteListDirection.multi] is passed - will
  /// render infinite list in both directions
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

  /// Proxy property for [ScrollView.reverse]
  ///
  /// Package doesn't support it yet.
  ///
  /// But as temporary solution similar result can be achieved
  /// with some config combination, described in README.md
  final bool reverse = false;

  /// Proxy property for [ScrollView.anchor]
  final double anchor;

  /// Proxy property for [RenderViewportBase.cacheExtent]
  final double cacheExtent;

  /// Scroll direction
  ///
  /// Can be vertical or horizontal (see [Axis] class)
  ///
  /// This value also affects how bottom or top
  /// edge header positioned headers behave
  final Axis scrollDirection;

  final Key _centerKey;

  InfiniteList({
    Key key,
    @required this.builder,
    this.controller,
    this.direction = InfiniteListDirection.single,
    this.maxChildCount,
    this.minChildCount,
    //this.reverse = false,
    this.anchor = 0.0,
    this.cacheExtent,
    this.scrollDirection = Axis.vertical,
  })  : _centerKey = (direction == InfiniteListDirection.multi) ? UniqueKey() : null,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _InfiniteListState();
}

class _InfiniteListState extends State<InfiniteList> {
  StreamController<StickyState> _streamController =
      StreamController<StickyState<int>>.broadcast();

  int get _reverseChildCount =>
      widget.minChildCount == null ? null : widget.minChildCount * -1;

  SliverList get _reverseList =>
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) =>
              _getListItem(context, (index + 1) * -1),
          childCount: _reverseChildCount,
        ),
      );

  SliverList get _forwardList =>
      SliverList(
        delegate: SliverChildBuilderDelegate(
          _getListItem,
          childCount: widget.maxChildCount,
        ),
        key: widget._centerKey,
      );

  Widget _getListItem(BuildContext context, int index) =>
      _StickySliverListItem<int>(
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
    reverse: widget.reverse,
    anchor: widget.anchor,
    cacheExtent: widget.cacheExtent,
    scrollDirection: widget.scrollDirection,
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

  Stream<StickyState<I>> get _stream =>
      streamController.stream.where((state) => state.index == index);

  _StickySliverListItem({
    Key key,
    this.index,
    this.listItem,
    this.streamController,
  }) : super(key: key);

  @override
  State<_StickySliverListItem<I>> createState() =>
      _StickySliverListItemState<I>();

  /// Maps sticky header alignment values
  /// to [AlignmentDirectional] variant
  AlignmentDirectional get alignment {
    switch (listItem.headerAlignment) {
      case HeaderAlignment.centerLeft:
        return AlignmentDirectional.centerStart;

      case HeaderAlignment.centerRight:
        return AlignmentDirectional.centerEnd;

      case HeaderAlignment.bottomLeft:
        return AlignmentDirectional.bottomStart;

      case HeaderAlignment.bottomCenter:
        return AlignmentDirectional.bottomCenter;

      case HeaderAlignment.bottomRight:
        return AlignmentDirectional.bottomEnd;

      case HeaderAlignment.bottomCenter:
        return AlignmentDirectional.bottomCenter;

      case HeaderAlignment.topRight:
        return AlignmentDirectional.topEnd;

      case HeaderAlignment.topLeft:
      default:
        return AlignmentDirectional.topStart;
    }
  }
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
      header: widget.listItem._getHeader(
        context,
        widget._stream,
        widget.index
      ),
      content: content,
      minOffsetProvider: widget.listItem.minOffsetProvider,
      alignment: widget.alignment,
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

  StickyListItem({
    @required Widget header,
    @required Widget content,
    @required this.itemIndex,
    this.minOffsetProvider,
    this.streamSink,
    AlignmentDirectional alignment,
    Key key,
  }) : super(
          key: key,
          children: [content, header],
          alignment: alignment ?? AlignmentDirectional.topStart,
          overflow: Overflow.clip,
        );

  ScrollableState _getScrollableState(BuildContext context) =>
      Scrollable.of(context);

  @override
  RenderStack createRenderObject(BuildContext context) =>
      StickyListItemRenderObject<I>(
        scrollable: _getScrollableState(context),
        alignment: alignment,
        textDirection: textDirection ?? Directionality.of(context),
        fit: fit,
        overflow: overflow,
        itemIndex: itemIndex,
        streamSink: streamSink,
        minOffsetProvider: minOffsetProvider,
      );

  @override
  @mustCallSuper
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    super.updateRenderObject(context, renderObject);

    if (renderObject is StickyListItemRenderObject<I>) {
      renderObject
        ..scrollable = _getScrollableState(context)
        ..itemIndex = itemIndex
        ..streamSink = streamSink
        ..minOffsetProvider = minOffsetProvider;
    }
  }
}
