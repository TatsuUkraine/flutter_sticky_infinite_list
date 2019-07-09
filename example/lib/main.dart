import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sticky_infinite_list/sticky_infinite_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StreamController<Settings> _streamController = StreamController<Settings>.broadcast();
  final ScrollController _scrollController = ScrollController();
  Settings _settings = Settings();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: Column(
      children: <Widget>[
        Container(
          child: ExpansionTile(
            title: Text("Settings"),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      title: Text("Render negative infinite list"),
                      value: _settings.multiDirection,
                      onChanged: (value) {
                        setState(() {
                          _settings.multiDirection = value;
                        });
                      },
                    ),
                    ListTile(
                      title: Text("Max number of items"),
                      trailing: DropdownButton<int>(
                        value: _settings.maxCount == null ? 0 : _settings.maxCount,
                        items: [
                          DropdownMenuItem(
                            child: Text("Infinite"),
                            value: 0,
                          ),
                        ]..addAll(
                            [10, 20, 30, 40].map((value) => DropdownMenuItem(
                                child: Text(value.toString()),
                                value: value
                            ))
                        ),
                        onChanged: (value) {
                          setState(() {
                            _settings.maxCount = value == 0 ? null : value;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text("Min number of items"),
                      trailing: DropdownButton<int>(
                        value: _settings.minCount == null ? 0 : _settings.minCount,
                        items: [
                          DropdownMenuItem(
                            child: Text("Infinite"),
                            value: 0,
                          ),
                        ]..addAll(
                            [-10, -20, -30, -40].map((value) => DropdownMenuItem(
                                child: Text(value.toString()),
                                value: value
                            ))
                        ),
                        onChanged: (value) {
                          setState(() {
                            _settings.minCount = value == 0 ? null : value;
                          });
                        },
                      ),
                    ),
                    Center(
                      child: RaisedButton(
                        child: Text("Scroll to center"),
                        onPressed: () {
                          _scrollController.animateTo(
                              0,
                              duration: Duration(seconds: 1),
                              curve: Curves.linearToEaseOut,
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ),
        Flexible(
          child: ScrollWidget(
            settings: _settings,
            scrollController: _scrollController,
            stream: _streamController.stream,
          ),
        )
      ],
    ),
  );

  @override
  void dispose() {
    super.dispose();

    _streamController.close();
  }
}

class ScrollWidget extends StatelessWidget {
  final Stream<Settings> stream;
  final ScrollController scrollController;
  final Settings settings;

  const ScrollWidget({
    Key key,
    this.stream,
    this.scrollController,
    this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => InfiniteList(
    controller: scrollController,
    direction: settings.multiDirection ? InfiniteListDirection.multi : InfiniteListDirection.single,
    minChildCount: settings.minCount,
    maxChildCount: settings.maxCount,
    builder: (context, index) {
      final date = DateTime.now().add(
          Duration(
            days: index,
          )
      );

      return InfiniteListItem(
        headerStateBuilder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(1 - state.position),
            ),
            height: 70,
            width: 70,
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 21,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat.MMM().format(date),
                  style: TextStyle(
                    height: .7,
                    fontSize: 17,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                )
              ],
            ),
          );
        },
        contentBuilder: (context) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.blueAccent,
          ),
          margin: EdgeInsets.only(
            left: 90,
            bottom: 10,
            right: 10,
          ),
          padding: EdgeInsets.all(8),
          height: 300,
          width: double.infinity,
          child: Text(
            DateFormat.yMMMMd().format(date),
            style: TextStyle(
                fontSize: 18,
                color: Colors.white
            ),
          ),
        ),
        minOffsetProvider: (state) => 80,
      );
    },
  );

}

class Settings {
  int minCount;
  int maxCount;
  bool multiDirection;

  Settings({
    this.minCount,
    this.maxCount,
    this.multiDirection = false,
  });
}
