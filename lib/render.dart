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
  bool _reverse;

  double _lastOffset;
  bool _headerOverflow = false;

  StickyListItemRenderObject({
    @required ScrollableState scrollable,
    @required I itemIndex,
    MinOffsetProvider<I> minOffsetProvider,
    StreamSink<StickyState<I>> streamSink,
    AlignmentGeometry alignment,
    TextDirection textDirection,
    StackFit fit,
    Overflow overflow,
    bool reverse = false,
  })  : _scrollable = scrollable,
        _streamSink = streamSink,
        _itemIndex = itemIndex,
        _minOffsetProvider = minOffsetProvider,
        _reverse = reverse,
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

  MinOffsetProvider<I> get minOffsetProvider =>
      _minOffsetProvider ?? (state) => 0;

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

  bool get reverse => _reverse;

  set reverse(bool reverse) {
    _reverse = reverse;
    markNeedsPaint();
  }

  RenderBox get _headerBox => lastChild;
  RenderBox get _contentBox => firstChild;

  RenderAbstractViewport get _viewport => RenderAbstractViewport.of(this);

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

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      _headerOverflow ? Offset.zero & size : null;

  @override
  void paint(PaintingContext context, Offset paintOffset) {
    updateHeaderOffset();

    if (overflow == Overflow.clip && _headerOverflow) {
      context.pushClipRect(
          needsCompositing, paintOffset, Offset.zero & size, paintStack);
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
    final double contentSize = _getContentDirectionSize();
    final double headerSize = _getHeaderDirectionSize();

    final double offset = _getStateOffset(stuckOffset, contentSize);
    final double position = offset / contentSize;

    final StickyState state = StickyState<I>(
      itemIndex,
      position: position,
      offset: offset,
      contentSize: contentSize,
    );

    final double headerOffset = _getHeaderOffset(state, stuckOffset, headerSize);

    parentData.offset = Offset(
      parentData.offset.dx,
      headerOffset
        //max(maxOffset, min(-stuckOffset, contentHeight)) - headerHeight
    );

    _headerOverflow = _isHeaderOverflow(headerOffset, headerSize, contentSize);

    if (_lastOffset != offset) {
      _lastOffset = offset;

      //todo: define when header sticky
      streamSink?.add(state);
    }
  }

  bool get _alignmentStart {
    return [AlignmentDirectional.topStart, AlignmentDirectional.topEnd].contains(alignment);
  }

  double get _scrollableSize {
    if (_alignmentStart) {
      return 0;
    }

    return _scrollable.context.size.height;
  }

  double _getStuckOffset() {
    final scrollBox = scrollable.context.findRenderObject();
    if (scrollBox?.attached ?? false) {
      final revealedOffset = _viewport.getOffsetToReveal(this, 0);

      return revealedOffset.offset - _scrollable.position.pixels - _scrollableSize;
    }

    return null;
  }

  double _getContentDirectionSize() {
    return _contentBox.size.height;
  }

  double _getHeaderDirectionSize() {
    return _headerBox.size.height;
  }

  double _getStateOffset(double stuckOffset, double contentSize) {
    double offset = _getOffset(stuckOffset, 0, contentSize);

    if (!_alignmentStart) {
      return contentSize - offset;
    }

    return offset;
  }

  double _getHeaderOffset(StickyState<I> state, double stuckOffset, double headerSize) {
    final double minOffset = _getMinOffset(state);

    if (!_alignmentStart) {
      return _getOffset(stuckOffset, minOffset, state.contentSize) - headerSize;
    }

    return _getOffset(stuckOffset, 0, minOffset);
  }

  double _getOffset(double current, double minPosition, double maxPosition) {
    return max(minPosition, min(-current, maxPosition));
  }

  double _getMinOffset(StickyState<I> state) {
    double minOffset = minOffsetProvider(state);

    if (_alignmentStart) {
      return state.contentSize - minOffset;
    }

    return minOffset;
  }

  bool _isHeaderOverflow(double headerOffset, double headerSize, double contentSize) {
    return headerOffset < 0 || headerOffset + headerSize > contentSize;
  }
}
