import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import './state.dart';

enum HeaderPositionAxis {
  mainAxis,
  crossAxis,
}

enum HeaderMainAxisAlignment {
  start,
  end,
}

enum HeaderCrossAxisAlignment {
  start,
  center,
  end,
}

class StickyListItemRenderObject<I> extends RenderStack {
  ScrollableState _scrollable;
  StreamSink<StickyState<I>> _streamSink;
  I _itemIndex;
  MinOffsetProvider<I> _minOffsetProvider;
  bool _overlayContent;
  HeaderPositionAxis _headerPositionAxis;
  HeaderMainAxisAlignment _mainAxisAlignment;
  HeaderCrossAxisAlignment _crossAxisAlignment;

  double _lastOffset;
  bool _headerOverflow = false;

  StickyListItemRenderObject({
    @required ScrollableState scrollable,
    @required I itemIndex,
    MinOffsetProvider<I> minOffsetProvider,
    StreamSink<StickyState<I>> streamSink,
    TextDirection textDirection,
    Overflow overflow,
    bool overlayContent,
    HeaderPositionAxis headerPositionAxis,
    HeaderMainAxisAlignment mainAxisAlignment,
    HeaderCrossAxisAlignment crossAxisAlignment,
  })  : _scrollable = scrollable,
        _streamSink = streamSink,
        _itemIndex = itemIndex,
        _minOffsetProvider = minOffsetProvider,
        _overlayContent = overlayContent,
        _headerPositionAxis = headerPositionAxis,
        _mainAxisAlignment = mainAxisAlignment,
        _crossAxisAlignment = crossAxisAlignment,
        super(
          alignment: _headerAlignment(scrollable, mainAxisAlignment, crossAxisAlignment),
          textDirection: textDirection,
          fit: StackFit.loose,
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
      _minOffsetProvider ?? (state) => null;

  set minOffsetProvider(MinOffsetProvider<I> offsetProvider) {
    _minOffsetProvider = offsetProvider;
    markNeedsPaint();
  }

  set overlayContent(bool overlayContent) {
    _overlayContent = overlayContent;
    markNeedsPaint();
  }

  set headerPositionAxis(HeaderPositionAxis headerPositionAxis) {
    _headerPositionAxis = headerPositionAxis;
    markNeedsPaint();
  }

  set mainAxisAlignment(HeaderMainAxisAlignment axisAlignment) {
    _mainAxisAlignment = axisAlignment;
    alignment = _headerAlignment(scrollable, _mainAxisAlignment, _crossAxisAlignment);
  }

  set crossAxisAlignment(HeaderCrossAxisAlignment axisAlignment) {
    _crossAxisAlignment = axisAlignment;
    alignment = _headerAlignment(scrollable, _mainAxisAlignment, _crossAxisAlignment);
  }

  ScrollableState get scrollable => _scrollable;

  set scrollable(ScrollableState newScrollable) {
    assert(newScrollable != null);

    final ScrollableState oldScrollable = _scrollable;
    _scrollable = newScrollable;

    markNeedsPaint();

    if (attached) {
      oldScrollable.position.removeListener(markNeedsPaint);
      newScrollable.position.addListener(markNeedsPaint);
    }
  }

  RenderBox get _headerBox => lastChild;
  RenderBox get _contentBox => firstChild;

  RenderAbstractViewport get _viewport => RenderAbstractViewport.of(this);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    scrollable.position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    scrollable.position.removeListener(markNeedsPaint);
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

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final RenderBox content = _contentBox;
    final RenderBox header = _headerBox;

    content.layout(constraints.loosen(), parentUsesSize: true);

    final Size childSize = content.size;

    double width = max(constraints.minWidth, childSize.width);
    double height = max(constraints.minHeight, childSize.height);

    if (!_overlayContent) {
      final Size headerSize = header.size;

      switch (_headerPositionAxis) {
        case HeaderPositionAxis.mainAxis:
          if (_scrollDirectionVertical) {
            height += max(constraints.minHeight, headerSize.height);
          } else {
            width += max(constraints.minWidth, headerSize.width);
          }

          break;

        case HeaderPositionAxis.crossAxis:
          if (_scrollDirectionVertical) {
            width += max(constraints.minWidth, headerSize.width);
          } else {
            height += max(constraints.minHeight, headerSize.height);
          }

          break;
      }
    }

    size = Size(width, height);
    assert(size.width == constraints.constrainWidth(width));
    assert(size.height == constraints.constrainHeight(height));

    assert(size.isFinite);

    final StackParentData contentParentData = content.parentData as StackParentData;

    contentParentData.offset = Offset.zero;

    final StackParentData headerParentData = _headerBox.parentData as StackParentData;

    RenderStack.layoutPositionedChild(_headerBox, headerParentData, size, alignment);
  }

  void updateHeaderOffset() {
    _headerOverflow = false;

    final double stuckOffset = _stuckOffset;

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

    final double headerOffset = _calculateHeaderOffset(
      contentSize,
      stuckOffset,
      headerSize,
      minOffsetProvider(state)
    );

    parentData.offset = _getDirectionalOffset(
      parentData.offset,
      headerOffset
    );

    _headerOverflow = _isHeaderOverflow(headerOffset, headerSize, contentSize);

    if (_lastOffset != offset) {
      _lastOffset = offset;

      streamSink?.add(state.copyWith(
        sticky: _isSticky(
          state,
          headerOffset,
          _calculateHeaderOffset(
            contentSize,
            stuckOffset,
            headerSize
          )
        )
      ));
    }
  }

  bool get _scrollDirectionVertical =>
      [AxisDirection.up, AxisDirection.down].contains(scrollable.axisDirection);

  bool get _alignmentStart => _mainAxisAlignment == HeaderMainAxisAlignment.start;

  double get _scrollableSize {
    final viewportContainer = _viewport;

    double viewportSize;

    if (viewportContainer is RenderBox) {
      final RenderBox viewportBox = viewportContainer as RenderBox;

      viewportSize = _scrollDirectionVertical
          ? viewportBox.size.height
          : viewportBox.size.width;
    }

    assert(viewportSize != null, 'Can\'t define view port size');

    double anchor = 0;

    if (viewportContainer is RenderViewport) {
      anchor = viewportContainer.anchor;
    }

    if (_alignmentStart) {
      return -viewportSize * anchor;
    }

    return viewportSize - viewportSize * anchor;
  }

  double get _stuckOffset {
      return _viewport.getOffsetToReveal(this, 0).offset - _scrollable.position.pixels - _scrollableSize;
  }

  double _getContentDirectionSize() {
    return _scrollDirectionVertical
        ? _contentBox.size.height
        : _contentBox.size.width;
  }

  double _getHeaderDirectionSize() {
    return _scrollDirectionVertical
        ? _headerBox.size.height
        : _headerBox.size.width;
  }

  Offset _getDirectionalOffset(Offset originalOffset, double offset) {
    if (_scrollDirectionVertical) {
      return Offset(
        originalOffset.dx,
        offset
      );
    }

    return Offset(
      offset,
      originalOffset.dy
    );
  }

  double _getStateOffset(double stuckOffset, double contentSize) {
    double offset = _getOffset(stuckOffset, 0, contentSize);

    if (_alignmentStart) {
      return offset;
    }

    return contentSize - offset;
  }

  double _calculateHeaderOffset(
    double contentSize,
    double stuckOffset,
    double headerSize,
    [double providedMinOffset = 0]
  ) {
    final double minOffset = _getMinOffset(contentSize, providedMinOffset);

    if (_alignmentStart) {
      return _getOffset(stuckOffset, 0, minOffset);
    }

    return _getOffset(stuckOffset, minOffset, contentSize) - headerSize;
  }

  double _getOffset(double current, double minPosition, double maxPosition) {
    return max(minPosition, min(-current, maxPosition));
  }

  double _getMinOffset(double contentSize, double minOffset) {
    if (_alignmentStart) {
      return contentSize - minOffset;
    }

    return minOffset;
  }

  bool _isHeaderOverflow(double headerOffset, double headerSize, double contentSize) {
    return headerOffset < 0 || headerOffset + headerSize > contentSize;
  }

  bool _isSticky(
    StickyState<I> state,
    double actualHeaderOffset,
    double headerOffset
  ) {
    return (
      actualHeaderOffset == headerOffset &&
      state.position > 0 &&
      state.position < 1
    );
  }

  static AlignmentGeometry _headerAlignment(ScrollableState scrollable, HeaderMainAxisAlignment mainAxisAlignment, HeaderCrossAxisAlignment crossAxisAlignment) {
    final bool vertical = [AxisDirection.up, AxisDirection.down].contains(scrollable.axisDirection);

    switch (crossAxisAlignment) {

      case HeaderCrossAxisAlignment.end:
        if (mainAxisAlignment == HeaderMainAxisAlignment.end) {
          return Alignment.bottomRight;
        }

        return vertical ? Alignment.bottomLeft : Alignment.topRight;

      case HeaderCrossAxisAlignment.center:
        if (mainAxisAlignment == HeaderMainAxisAlignment.start) {
          return vertical ? Alignment.centerLeft : Alignment.topCenter;
        }

        return vertical ? Alignment.centerRight : Alignment.bottomCenter;

      case HeaderCrossAxisAlignment.start:
      default:
        if (mainAxisAlignment == HeaderMainAxisAlignment.start) {
          return Alignment.topLeft;
        }

        return vertical ? Alignment.topRight : Alignment.bottomLeft;
    }
  }
}