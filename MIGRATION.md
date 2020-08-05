# Migration guide

## Migration From v1.x.x to v2.x.x

### Child count params

In `InfiniteList` next params for max child count was renamed:
- `minChildCount` was renamed to `negChildCount` and now it works with
  positive numbers
- `maxChildCount` was renamed to `posChildCount` and, as before, it
  works with positive numbers

### Header alignment

Param `headerAlignment` in `InfiniteListItem` was replaced with 2
params: `mainAxisAlignment` and `crossAxisAlignment`

Main axis is placed with scroll direction: vertical or horizontal.

With `mainAxisAlignment: HeaderMainAxisAlignment.start` and vertical
scroll header will stick to the top edge, with horizontal scroll - to
the left edge. Similar with `mainAxisAlignment:
HeaderMainAxisAlignment.end` - bottom and right side respectively.

`crossAxisAlignment` doesn't affect stick side. It just places header to
the left or right side for the vertical scroll, and top or bottom - for
horizontal scroll.

New parameter was added for relative positioning: `positionAxis` which
defines what direction should be used during layout - column or row.

### List item layout

Comparing to v1, v2 by default uses relative positioning.

To make header overlay content use constructor `overlay`. It's available
in both `InfiniteListItem` and `StickyListItem` widgets.

### Initial header render

In default constructor param `initialHeaderBuild` was removed.

Since default constructor uses relative positioning, header is required
to calculate appropriate item size.

`initialHeaderBuild` is still available in `overlay` constructors and
affects header render like it was before in v1.x.x

## Migration From v2.x.x to v3.x.x

### Render object constructor changes

In newer Flutter versions key `overflow` in `Stack` widgets and render
objects was replaced with `clipBehavior`.

Since `StickyListItemRenderObject` inherits `RenderStack`, sticky header
render object also was updated due to changes in Flutters render object.

So if you use `StickyListItemRenderObject` ensure to replace `overflow`
param with `clipBehavior`. By default it's `Clip.hardEdge`, according to
default `overflow` key, which was `Overflow.clip` by default
