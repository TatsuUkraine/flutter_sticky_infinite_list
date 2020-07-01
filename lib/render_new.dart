import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'models/alignments.dart';
import 'models/sticky_state.dart';
import 'models/types.dart';

///todo: rename file, remove old render object
///
/// Sticky item render object based on [RenderStack]
class StickyListItemRenderObject<I> extends RenderStack {
  ScrollableState _scrollable;
  StreamSink<StickyState<I>> _streamSink;
  I _itemIndex;
  MinOffsetProvider<I> _minOffsetProvider;
  bool _overlayContent;
  HeaderPositionAxis _positionAxis;
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
    HeaderPositionAxis positionAxis = HeaderPositionAxis.mainAxis,
    HeaderMainAxisAlignment mainAxisAlignment = HeaderMainAxisAlignment.start,
    HeaderCrossAxisAlignment crossAxisAlignment = HeaderCrossAxisAlignment.start,
  })  : _scrollable = scrollable,
        _streamSink = streamSink,
        _itemIndex = itemIndex,
        _minOffsetProvider = minOffsetProvider,
        _overlayContent = overlayContent,
        _positionAxis = positionAxis,
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

    if (_overlayContent != overlayContent) {
      markNeedsLayout();
    }
  }

  set positionAxis(HeaderPositionAxis positionAxis) {
    _positionAxis = positionAxis;

    if (_positionAxis != positionAxis) {
      markNeedsLayout();
    }
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
    final RenderBox header = _headerBox;

    final BoxConstraints containerConstraints = constraints.loosen();

    header.layout(containerConstraints, parentUsesSize: true);

    size = _layoutContent(containerConstraints, header.size);

    assert(size.width == constraints.constrainWidth(size.width));
    assert(size.height == constraints.constrainHeight(size.height));

    assert(size.isFinite);

    final StackParentData headerParentData = header.parentData as StackParentData;

    headerParentData.offset = alignment.resolve(textDirection).alongOffset(size - header.size as Offset);
  }

  void updateHeaderOffset() {
    _headerOverflow = false;

    final double stuckOffset = _stuckOffset;

    final StackParentData parentData = _headerBox.parentData;
    final double contentSize = _contentDirectionSize;
    final double headerSize = _headerDirectionSize;

    final double offset = _calculateStateOffset(stuckOffset, contentSize);
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

    parentData.offset = _headerDirectionalOffset(
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

  @override
  double computeMinIntrinsicWidth(double height) {
    if (
      _overlayContent ||
      _scrollDirectionVertical && _positionAxis == HeaderPositionAxis.mainAxis ||
      !_scrollDirectionVertical && _positionAxis == HeaderPositionAxis.crossAxis
    ) {
      return _contentBox.getMinIntrinsicWidth(height);
    }

    return _contentBox.getMinIntrinsicWidth(height) + _headerBox.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (
      _overlayContent ||
      _scrollDirectionVertical && _positionAxis == HeaderPositionAxis.mainAxis ||
      !_scrollDirectionVertical && _positionAxis == HeaderPositionAxis.crossAxis
    ) {
      return _contentBox.getMaxIntrinsicWidth(height);
    }

    return _contentBox.getMaxIntrinsicWidth(height) + _headerBox.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (
      _overlayContent ||
      _scrollDirectionVertical && _positionAxis == HeaderPositionAxis.crossAxis ||
      !_scrollDirectionVertical && _positionAxis == HeaderPositionAxis.mainAxis
    ) {
      return _contentBox.getMinIntrinsicHeight(width);
    }

    return _contentBox.getMinIntrinsicHeight(width) + _headerBox.getMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (
      _overlayContent ||
      _scrollDirectionVertical && _positionAxis == HeaderPositionAxis.crossAxis ||
      !_scrollDirectionVertical && _positionAxis == HeaderPositionAxis.mainAxis
    ) {
      return _contentBox.getMinIntrinsicHeight(width);
    }

    return _contentBox.getMinIntrinsicHeight(width) + _headerBox.getMinIntrinsicHeight(width);
  }

  bool get _scrollDirectionVertical => _scrollableAxisVertical(scrollable.axisDirection);

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

  double get _contentDirectionSize => _scrollDirectionVertical
      ? size.height
      : size.width;

  double get _headerDirectionSize => _scrollDirectionVertical
      ? _headerBox.size.height
      : _headerBox.size.width;

  Offset _headerDirectionalOffset(Offset originalOffset, double offset) {
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

  double _calculateStateOffset(double stuckOffset, double contentSize) {
    double offset = _calculateOffset(stuckOffset, 0, contentSize);

    if (_alignmentStart) {
      return offset;
    }

    return contentSize - offset;
  }

  double _calculateHeaderOffset(
    double contentSize,
    double stuckOffset,
    double headerSize,
    [double providedMinOffset]
  ) {
    if (providedMinOffset == null) {
      providedMinOffset = headerSize;
    }

    final double minOffset = _calculateMinOffset(contentSize, providedMinOffset);

    if (_alignmentStart) {
      return _calculateOffset(stuckOffset, 0, minOffset);
    }

    return _calculateOffset(stuckOffset, minOffset, contentSize) - headerSize;
  }

  double _calculateOffset(double current, double minPosition, double maxPosition) {
    return max(minPosition, min(-current, maxPosition));
  }

  double _calculateMinOffset(double contentSize, double minOffset) {
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

  Size _layoutContent(BoxConstraints constraints, Size headerSize) {
    final RenderBox content = _contentBox;
    final StackParentData contentParentData = content.parentData as StackParentData;

    if (!_overlayContent) {
      final bool alignmentStart = _mainAxisAlignment ==
          HeaderMainAxisAlignment.start ||
          _crossAxisAlignment == HeaderCrossAxisAlignment.start;

      if (
      (
          _positionAxis == HeaderPositionAxis.crossAxis &&
              _scrollDirectionVertical
      ) ||
          (
              _positionAxis == HeaderPositionAxis.mainAxis &&
                  !_scrollDirectionVertical
          )
      ) {
        content.layout(constraints.copyWith(
            maxWidth: constraints.maxWidth - headerSize.width
        ), parentUsesSize: true);

        if (alignmentStart) {
          contentParentData.offset = Offset(headerSize.width, 0);
        }

        final Size contentSize = content.size;

        return Size(
            contentSize.width + headerSize.width,
            contentSize.height
        );
      }

      if (
      (
          _positionAxis == HeaderPositionAxis.mainAxis &&
              _scrollDirectionVertical
      ) ||
          (
              _positionAxis == HeaderPositionAxis.crossAxis &&
                  !_scrollDirectionVertical
          )
      ) {
        content.layout(constraints.copyWith(
            maxHeight: constraints.maxHeight - headerSize.height
        ), parentUsesSize: true);

        if (alignmentStart) {
          contentParentData.offset = Offset(0, headerSize.height);
        }

        final Size contentSize = content.size;

        return Size(
            contentSize.width,
            contentSize.height + headerSize.height
        );
      }
    }

    content.layout(constraints, parentUsesSize: true);
    contentParentData.offset = Offset.zero;

    return content.size;
  }

  static AlignmentGeometry _headerAlignment(ScrollableState scrollable, HeaderMainAxisAlignment mainAxisAlignment, HeaderCrossAxisAlignment crossAxisAlignment) {
    final bool vertical = _scrollableAxisVertical(scrollable.axisDirection);

    switch (crossAxisAlignment) {

      case HeaderCrossAxisAlignment.end:
        if (mainAxisAlignment == HeaderMainAxisAlignment.end) {
          return Alignment.bottomRight;
        }

        return vertical ? Alignment.topRight : Alignment.bottomLeft;

      case HeaderCrossAxisAlignment.center:
        if (mainAxisAlignment == HeaderMainAxisAlignment.start) {
          return vertical ? Alignment.topCenter : Alignment.centerLeft;
        }

        return vertical ? Alignment.bottomCenter : Alignment.centerRight;

      case HeaderCrossAxisAlignment.start:
      default:
        if (mainAxisAlignment == HeaderMainAxisAlignment.start) {
          return Alignment.topLeft;
        }

        return vertical ? Alignment.bottomLeft : Alignment.topRight;
    }
  }

  static bool _scrollableAxisVertical(AxisDirection direction) => [AxisDirection.up, AxisDirection.down].contains(direction);
}
