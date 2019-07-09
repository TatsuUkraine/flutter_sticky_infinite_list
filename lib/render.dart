import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import './state.dart';

class StickyListItemRenderObject<I> extends RenderStack {
  ScrollableState _scrollable;
  StreamSink<StickyState<I>> _streamSink;
  I _itemIndex;
  MinOffsetProvider<I> _minOffsetProvider;

  double _lastOffset;
  bool _headerOverflow = false;

  StickyListItemRenderObject({
    @required ScrollableState scrollable,
    @required I itemIndex,
    @required MinOffsetProvider<I> minOffsetProvider,
    StreamSink<StickyState<I>> streamSink,
    AlignmentGeometry alignment,
    TextDirection textDirection,
    StackFit fit,
    Overflow overflow,
  }): _scrollable = scrollable,
      _streamSink = streamSink,
      _itemIndex = itemIndex,
      _minOffsetProvider = minOffsetProvider,
      super(
        alignment: alignment,
        textDirection: textDirection,
        fit: fit,
        overflow: overflow,
      );

  StreamSink<StickyState<I>> get streamSink => _streamSink;

  set streamSink(StreamSink<StickyState<I>> sink) {
    _streamSink = sink;
    markNeedsPaint();
  }

  I get itemIndex => _itemIndex;

  set itemIndex(I index) {
    _itemIndex = index;
    markNeedsPaint();
  }

  MinOffsetProvider<I> get minOffsetProvider => _minOffsetProvider;

  set minOffsetProvider(MinOffsetProvider<I> offsetProvider) {
    _minOffsetProvider = offsetProvider;
    markNeedsPaint();
  }

  ScrollableState get scrollable => _scrollable;

  set scrollable(ScrollableState newScrollable) {
    assert(newScrollable != null);

    final ScrollableState oldScrollable = _scrollable;
    _scrollable = newScrollable;

    markNeedsPaint();

    if (attached) {
      oldScrollable.widget.controller.removeListener(markNeedsPaint);
      newScrollable.widget.controller.addListener(markNeedsPaint);
    }
  }

  RenderBox get _headerBox => lastChild;
  RenderBox get _contentBox => firstChild;

  RevealedOffset get _viewportRevealedOffset => RenderAbstractViewport.of(this).getOffsetToReveal(this, 0);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    scrollable.widget.controller.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    scrollable.widget.controller.removeListener(markNeedsPaint);
    super.detach();
  }

  double _getStuckOffset() {
    final scrollBox = scrollable.context.findRenderObject();
    if (scrollBox?.attached ?? false) {
      return _viewportRevealedOffset.offset - _scrollable.position.pixels;
    }

    return null;
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _headerOverflow ? Offset.zero & size : null;

  @override
  void paint(PaintingContext context, Offset paintOffset) {
    updateHeaderOffset();

    if (overflow == Overflow.clip && _headerOverflow) {
      context.pushClipRect(needsCompositing, paintOffset, Offset.zero & size, paintStack);
    } else {
      paintStack(context, paintOffset);
    }
  }

  void updateHeaderOffset() {
    _headerOverflow = false;
    final double stuckOffset = _getStuckOffset();

    if (stuckOffset == null) {
      return;
    }

    final StackParentData parentData = _headerBox.parentData;
    final double headerHeight = _headerBox.size.height;
    final double contentHeight = max(constraints.minHeight, _contentBox.size.height);

    final double offset = max(0.0, min(-stuckOffset, contentHeight));
    final double position = offset/contentHeight;

    final StickyState state = StickyState<I>(
      itemIndex,
      position: position,
      offset: offset,
      contentHeight: contentHeight,
    );

    final double maxOffset = contentHeight - minOffsetProvider(state);
    parentData.offset = Offset(0, max(0.0, min(-stuckOffset, maxOffset)));

    _headerOverflow = (offset + headerHeight >= contentHeight);

    if (_lastOffset != offset) {
      _lastOffset = offset;

      streamSink?.add(state.copyWith(
        sticky: stuckOffset < 0 && maxOffset + stuckOffset > 0,
      ));
    }
  }
}