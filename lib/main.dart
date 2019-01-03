import 'package:flutter/material.dart';
import 'spinning_dial.dart';

void main() => runApp(MyApp());

Widget createFace(int index) {
  var key = (index + 1).toString();

  var colors = [
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.red
  ];

  return ClipRect(
    key: Key(key),
    child: Align(
      alignment: Alignment.center,
      child: Container(
        key: Key(key),
        color: colors[index],
        padding: EdgeInsets.all(20.0),
        child: Text(
          key,
          key: Key(key),
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.0,
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perspective',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key); // changed

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DialController controller;

  @override
  void initState() {
    controller = DialController();
    super.initState();
  }

  int _value;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Container(
        color: Colors.green,
        child: Padding(
          padding: const EdgeInsets.only(top: 180.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              SpinningDialView(
                children: <Widget>[
                  createFace(0),
                  createFace(1),
                  createFace(2),
                  createFace(3),
                  createFace(4),
                  createFace(5),
                ],
                itemExtent: 75.0,
                onSelectedItemChanged: (int newValue) {
                  _value = newValue.round();
                  print(_value);
                  print("Controller value: ${controller.selectedItem}");
                },
                controller: controller,
              ),
              SpinningDialView(
                children: <Widget>[
                  createFace(0),
                  createFace(1),
                  createFace(2),
                  createFace(3),
                  createFace(4),
                  createFace(5),
                ],
                itemExtent: 75.0,
                onSelectedItemChanged: (int newValue) {
                  _value = newValue.round();
                  print(_value);
                },
              ),
              SpinningDialView(
                children: <Widget>[
                  createFace(0),
                  createFace(1),
                  createFace(2),
                  createFace(3),
                  createFace(4),
                  createFace(5),
                ],
                itemExtent: 75.0,
                onSelectedItemChanged: (int newValue) {
                  _value = newValue.round();
                  print(_value);
                },
              ),
              SpinningDialView(
                children: <Widget>[
                  createFace(0),
                  createFace(1),
                  createFace(2),
                  createFace(3),
                  createFace(4),
                  createFace(5),
                ],
                itemExtent: 75.0,
                onSelectedItemChanged: (int newValue) {
                  _value = newValue.round();
                  print(_value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
