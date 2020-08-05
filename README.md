# Sticky Infinite List

[![pub package](https://img.shields.io/pub/v/sticky_infinite_list.svg)](https://pub.dartlang.org/packages/sticky_infinite_list)
<a href="https://github.com/Solido/awesome-flutter">
   <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>

Infinite list with sticky headers.

This package was made in order to make possible
render infinite list in both directions with sticky headers, unlike most
packages in Dart Pub.

Supports various header positioning. Also supports Vertical and
Horizontal scroll list

It highly customizable and doesn't have any third party dependencies or native(Android/iOS) code.

In addition to default usage, this package exposes some classes, that
can be overridden if needed. Also some classes it can be used inside
Scrollable widgets independently from `InfiniteList` container.

This package uses `CustomScrollView` to perform scroll with all
benefits for performance that Flutter provides.

## Features

- sticky headers within infinite list
- multi directional infinite list
- customization for sticky header position
- horizontal sticky list support
- dynamic header build on content scroll
- dynamic min offset calculation on content scroll

## Flutter before 1.20

If you're using Flutter version lower than 1.20 consider using v2.x.x.

## Migration guide

If you using older MAJOR versions, please
[visit this migration guide](https://github.com/TatsuUkraine/flutter_sticky_infinite_list/blob/master/MIGRATION.md)

### Property not defined

If you get similar error message during the build please read [this
section](#flutter-version-related-errors) first.

## Demo

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/2277e153e7c723bca0a746b2730c5abef4cfe25e/doc/images/base_scroll.gif" width="50%" />

## Getting Started

Install package and import

```dart

import 'package:sticky_infinite_list/sticky_infinite_list.dart';
```

Package exposes `InfiniteList`, `InfiniteListItem`, `StickyListItem`,
`StickyListItemRenderObject` classes

## Examples

### Simple example

To start using Infinite list with sticky headers,
you need to create instance `InfiniteList` with builder specified.

No need to specify any additional config to make it work

```dart

import 'package:sticky_infinite_list/sticky_infinite_list.dart';

class Example extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      builder: (BuildContext context, int index) {
        /// Builder requires [InfiniteList] to be returned
        return InfiniteListItem(
          /// Header builder
          headerBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
          /// Content builder
          contentBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
        );
      }
    );
  }
}
```

Or with header overlay content
```dart

import 'package:sticky_infinite_list/sticky_infinite_list.dart';

class Example extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      builder: (BuildContext context, int index) {
        /// Builder requires [InfiniteList] to be returned
        return InfiniteListItem.overlay(
          /// Header builder
          headerBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
          /// Content builder
          contentBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
        );
      }
    );
  }
}
```

### State

When min offset callback invoked or header builder is invoked
object `StickyState` is passed as parameter

This object describes current state for sticky header.

```dart
class StickyState<I> {
  /// Position, that header already passed
  ///
  /// Value can be between 0.0 and 1.0
  ///
  /// If it's `0.0` - sticky in max start position
  ///
  /// `1.0` - max end position
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
  /// header render will be with position = 0
  final double position;

  /// Number of pixels, that outside of viewport
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
  /// header render will be with offset = 0
  /// 
  /// For header bottom positions (or right positions for horizontal)
  /// offset value also will be amount of pixels that was scrolled away
  final double offset;

  /// Item index
  final I index;

  /// If header is in sticky state
  ///
  /// If [InfiniteListItem.minOffsetProvider] is defined,
  /// it could be that header builder will be emitted with new state
  /// on scroll, but [sticky] will be false, if offset already passed
  /// min offset value
  ///
  /// WHen [InfiniteListItem.minOffsetProvider] is called, [sticky]
  /// will always be `false`. Since for min offset calculation
  /// offset itself not defined yet
  final bool sticky;

  /// Scroll item height.
  ///
  /// If [InfiniteListItem.initialHeaderBuild] is true, initial
  /// header render will be called without this value
  final double contentSize;
}
```

### Extended configuration

#### Available configuration

Alongside with minimal config to start using.

`InfiniteList` allows you to define config for scroll list rendering

```dart
InfiniteList(
  /// Optional parameter to pass ScrollController instance
  controller: ScrollController(),
  
  /// Optional parameter
  /// to specify scroll direction
  /// 
  /// By default scroll will be rendered with just positive
  /// direction `InfiniteListDirection.forward`
  /// 
  /// If you need infinite list in both directions use `InfiniteListDirection.multi`
  direction: InfiniteListDirection.multi,
  
  /// Negative max child count.
  /// 
  /// Will be used only when `direction: InfiniteListDirection.multi`
  /// 
  /// If it's not provided, scroll will be infinite in negative direction
  negChildCount: 100,
  
  /// Positive max child count
  /// 
  /// Specifies number of elements for forward list
  /// 
  /// If it's not provided, scroll will be infinite in positive direction
  posChildCount: 100,
  
  /// ScrollView anchor value.
  anchor: 0.0,
  
  /// ScrollView physics value.
  physics: null,

  /// Item builder
  /// 
  /// Should return `InfiniteListItem`
  builder: (BuildContext context, int index) {
    return InfiniteListItem(
      //...
    )
  }
)
```
 
`InfiniteListItem` allows you to specify more options for you customization.

```dart
InfiniteListItem(
  /// See class description for more info
  /// 
  /// Forces initial header render when [headerStateBuilder]
  /// is specified.
  initialHeaderBuild: false,

  /// Simple Header builder
  /// that will be called once during List item render
  headerBuilder: (BuildContext context) {},
  
  /// Header builder, that will be invoked each time
  /// when header should change it's position
  /// 
  /// Unlike prev method, it also provides `state` of header
  /// position
  /// 
  /// This callback has higher priority than [headerBuilder],
  /// so if both header builders will be provided,
  /// [headerBuilder] will be ignored
  headerStateBuilder: (BuildContext context, StickyState<int> state) {},
  
  /// Content builder
  contentBuilder: (BuildContext context) {},
  
  /// Min offset invoker
  /// 
  /// This callback is called on each header position change,
  /// to define when header should be stick to the bottom of
  /// content.
  /// 
  /// If this method returns `0`,
  /// header will be in sticky state until list item
  /// will be visible inside view port
  /// 
  /// If this method not provided or it returns null, header
  /// will be sticky until offset equals to 
  /// header size
  minOffsetProvider: (StickyState<int> state) {},
  
  /// Header alignment against main axis direction
  ///
  /// See [HeaderMainAxisAlignment] for more info
  HeaderMainAxisAlignment mainAxisAlignment: HeaderMainAxisAlignment.start,

  /// Header alignment against cross axis direction
  ///
  /// See [HeaderCrossAxisAlignment] for more info
  HeaderCrossAxisAlignment crossAxisAlignment: HeaderCrossAxisAlignment.start,

  /// Header position against scroll axis for relative positioned headers
  ///
  /// Only for relative header positioning
  HeaderPositionAxis positionAxis: HeaderPositionAxis.mainAxis,

  /// List item padding, see [EdgeInsets] for more info
  EdgeInsets padding: const EdgeInsets.all(8.0),
  
  /// Scroll direction
  ///
  /// Can be vertical or horizontal (see [Axis] class)
  ///
  /// This value also affects how bottom or top
  /// edge header positioned headers behave
  scrollDirection: Axis.vertical,
);
```

### Demos

#### Header alignment demo

Relative positioning

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/28c70054b5a11a4ba22e9a1a2b6b76b892c441b3/doc/images/header_position.gif" width="50%" />

Relative cross axis positioning

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/28c70054b5a11a4ba22e9a1a2b6b76b892c441b3/doc/images/header_cross_position.gif" width="50%" />

Overlay positioning

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/28c70054b5a11a4ba22e9a1a2b6b76b892c441b3/doc/images/header_position_overlay.gif" width="50%" />

#### Horizontal scroll demo

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/ab9ec55223c2a60192559fed553634a7f358b002/doc/images/horizontal_scroll.gif" width="50%" />

### Reverse infinite scroll

Currently package doesn't support `CustomScrollView.reverse` option.

But same result can be achieved with defining `anchor = 1` and
`posChildCount = 0`. In that way viewport center will be stick to the
bottom and positive list won't render anything.

Additionally you can specify header alignment to any side.

```dart
import 'package:sticky_infinite_list/sticky_infinite_list.dart';

class Example extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return InfiniteList(
      anchor: 1.0,
      
      direction: InfiniteListDirection.multi,
      
      posChildCount: 0,
      
      builder: (BuildContext context, int index) {
        /// Builder requires [InfiniteList] to be returned
        return InfiniteListItem(
        
          mainAxisAlignment: HeaderMainAxisAlignment.end,
          crossAxisAlignment: HeaderCrossAxisAlignment.start,
          
          /// Header builder
          headerBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
          /// Content builder
          contentBuilder: (BuildContext context) {
            return Container(
              ///...
            );
          },
        );
      }
    );
  }
}
``` 

#### Demo

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/e7a35fba60c9f4da97e84131a8c342424819aae7/doc/images/reverse_scroll.gif" width="50%" />

For more info take a look at
[Example](https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example) project

### Available for override

In most cases it will be enough to just use `InfiniteListItem`

But in some cases you may need to add additional functionality to
each item.

Luckily you can extend and override base `InfiniteListItem` class

```dart
/// Generic `I` is index type, by default list item uses `int`

class SomeCustomListItem<I> extends InfiniteListItem<I> {
  /// Header alignment against main axis direction
  ///
  /// See [HeaderMainAxisAlignment] for more info
  @override
  final HeaderMainAxisAlignment mainAxisAlignment = HeaderMainAxisAlignment.start;

  /// Header alignment against cross axis direction
  ///
  /// See [HeaderCrossAxisAlignment] for more info
  @override
  final HeaderCrossAxisAlignment crossAxisAlignment = HeaderCrossAxisAlignment.start;

  /// Header position against scroll axis for relative positioned headers
  ///
  /// See [HeaderPositionAxis] for more info
  @override
  final HeaderPositionAxis positionAxis = HeaderPositionAxis.mainAxis;

  /// If header should overlay content or not
  @override
  final bool overlayContent = false;

  /// Let item builder know if it should watch
  /// header position changes
  /// 
  /// If this value is `true` - it will invoke [buildHeader]
  /// each time header position changes
  @override
  bool get watchStickyState => true;

  /// Let item builder know that this class
  /// provides header
  /// 
  /// If it returns `false` - [buildHeader] will be ignored 
  /// and never called
  @override
  bool get hasStickyHeader => true;

  /// This methods builds header
  /// 
  /// If [watchStickyState] is `true`,
  /// it will be invoked on each header position change
  /// and `state` option will be provided
  /// 
  /// Otherwise it will be called only once on initial render
  /// and each header position change won't invoke this method.
  /// 
  /// Also in that case `state` will be `null`
  @override
  Widget buildHeader(BuildContext context, [StickyState<I> state]) {}

  /// Content item builder
  /// 
  /// This method invoked only once
  @override
  Widget buildContent(BuildContext context) {}

  /// Called during init state (see [Statefull] widget [State.initState])
  /// 
  /// For additional information about [Statefull] widget `initState`
  /// lifecycle - see Flutter docs
  @protected
  @mustCallSuper
  void initState() {}

  /// Called during item dispose (see [Statefull] widget [State.dispose])
  /// 
  /// For additional information about [Statefull] widget `dispose`
  /// lifecycle - see Flutter docs
  @protected
  @mustCallSuper
  void dispose() {}
}
```

#### Need more override?..

Alongside with list item override, to use inside `InfiniteList` builder,
you can also use or extend `StickyListItem`, that exposed by this
package too, independently.

This class uses `Stream` to inform it's parent about header position changes

Also it requires to be rendered inside `Scrollable` widget and `Viewport`,
since it subscribes to scroll event and calculates position
against `Viewport` coordinates (see `StickyListItemRenderObject` class
for more information)

For example 

```dart
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Column(
      children: <Widget>[
        Container(
          height: height,
          color: Colors.lightBlueAccent,
          child: Placeholder(),
        ),
        StickyListItem<String>(
          streamSink: _headerStream.sink, /// stream to update header during scroll
          header: Container(
            height: _headerHeight,
            width: double.infinity,
            color: Colors.orange,
            child: Center(
              child: StreamBuilder<StickyState<String>>(
                stream: _headerStream.stream, /// stream to update header during scroll
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  final position = (snapshot.data.position * 100).round();

                  return Text('Positioned relative. Position: $position%');
                },
              ),
            ),
          ),
          content: Container(
            height: height,
            color: Colors.blueAccent,
            child: Placeholder(),
          ),
          itemIndex: "single-child",
        ),
        StickyListItem<String>.overlay(
          streamSink: _headerOverlayStream.sink, /// stream to update header during scroll
          header: Container(
            height: _headerHeight,
            width: double.infinity,
            color: Colors.orange,
            child: Center(
              child: StreamBuilder<StickyState<String>>(
                stream: _headerOverlayStream.stream, /// stream to update header during scroll
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }

                  final position = (snapshot.data.position * 100).round();

                  return Text('Positioned overlay. Position: $position%');
                },
              ),
            ),
          ),
          content: Container(
            height: height,
            color: Colors.lightBlueAccent,
            child: Placeholder(),
          ),
          itemIndex: "single-overlayed-child",
        ),
        Container(
          height: height,
          color: Colors.cyan,
          child: Placeholder(),
        ),
      ],
    ),
  );
}
```

This code will render single child scroll with 4 widgets. Two middle
items - items with sticky header.

**Demo**

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/raw/450dffae4a4e3a10496aa5dacf267e1511fe7cee/doc/images/single-scroll.gif" width="50%" />

For more complex example please take a look at "Single Example" page
in [Example project](https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example)

## Changelog

Please see the [Changelog](https://github.com/TatsuUkraine/flutter_sticky_infinite_list/blob/master/CHANGELOG.md) page to know what's recently changed.

## Bugs/Requests

If you encounter any problems feel free to open an [issue](https://github.com/TatsuUkraine/flutter_sticky_infinite_list/issues).
If you feel the library is missing a feature,
please raise a ticket on Github and I'll look into it.
Pull request are also welcome.

## Known issues

Currently this package can't work with reverse scroll. For some reason
flutter calculates coordinate for negative list items in a
different way in reverse mode, comparing to regular scroll direction.

But there is an workaround can be used, described
in [Reverse infinite scroll](#reverse-infinite-scroll)

## Flutter version related errors

### Named parameter clipBehavior isn't defined error

If you get this kind of error, most likely you are using Flutter 1.17.
If so, please ensure that you're using 2.x.x version.
