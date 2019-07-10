# Sticky Infinite List

Infinite list with sticky headers.

This package was made in order to make possible
render infinite list in both directions with sticky headers, unlike most
packages in Dart Pub.

It highly customizable and doesn't have any third party dependencies or native(Android/iOS) code.

In addition to default usage, this package exposes some classes, that
can be overridden if needed. Also some classes it can be used inside
Scrollable widgets independently from `InfiniteList` container.

This package uses `CustomScrollView` to perform scroll with all
benefits for performance that Flutter provides.

## Demo

<img src="https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example/blob/master/doc/images/example.gif?raw=true" width="50%" />

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
  
  /// Min child count.
  /// 
  /// Will be used only when `direction: InfiniteListDirection.multi`
  /// 
  /// Accepts negative values only
  minChildCount: -100,
  
  /// Max child count
  /// 
  /// Specifies number of elements for forward list
  maxChildCount: 100,

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
  /// If this method not provided or it returns `0`,
  /// header will be in sticky state until list item
  /// will be visible inside view port
  minOffsetProvider: (StickyState<int> state) {},
);
```

For more info take a look at
[Example](https://github.com/TatsuUkraine/flutter_sticky_infinite_list_example) project

### Available for override

In most cases it will be enough to just use `InfiniteListItem`

But in some cases you may need to add additional functionality to
each item.

Luckily you can extend and override base `InfiniteListItem` class

```dart
/// Generic `I` is index type, by default list item uses `int`
class SomeCustomListItem extends InfiniteListItem<I> {
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
  Widget buildContent(BuildContext context) => {}

  /// Called during init state (see Statefull widget [State.initState])
  /// 
  /// For additional information about Statefull widget `initState`
  /// lifecycle - see Flutter docs
  @protected
  @mustCallSuper
  void initState() {}

  /// Called during item dispose (see Statefull widget [State.dispose])
  /// 
  /// For additional information about Statefull widget `dispose`
  /// lifecycle - see Flutter docs
  @protected
  @mustCallSuper
  void dispose() {}
}
```

#### Need more override?.. Ok (not tested)

**If you get any problems with this type of override,
 please create an issue**

Alongside with list item override, to use inside `InfiniteList` builder,
you can also use `StickyListItem`, that exposed by this package too, independently.

This class uses `Stream` to inform it's parent about header position changes

Also it requires to be rendered inside `Scrollable` widget and `Viewport`,
since it subscribes to scroll event and calculates position
against `Viewport` coordinates (see `StickyListItemRenderObject` class
for more information)

## Changelog

Please see the [Changelog](https://github.com/TatsuUkraine/flutter_sticky_infinite_list/blob/master/CHANGELOG.md) page to know what's recently changed.

## Bugs/Requests

If you encounter any problems feel free to open an [issue](https://github.com/TatsuUkraine/flutter_sticky_infinite_list/issues).
If you feel the library is missing a feature,
please raise a ticket on Github and I'll look into it.
Pull request are also welcome.

## Known issues

Currently this package can't work with reverse lists. I hope I will
get enough time to implement this feature soon)
