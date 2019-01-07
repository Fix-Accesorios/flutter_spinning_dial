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
        padding: EdgeInsets.all(10.0),
        child: Text(
          key,
          key: Key(key),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
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
  int num = 0;
  @override
  void initState() {
    controller = DialController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Container(
        color: Colors.green,
        child: Column(
          children: <Widget>[
            Text(
              controller.selectedItem.toString(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 180.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SpinningDialView(
                    detent: 0.8,
                    children: <Widget>[
                      createFace(0),
                      createFace(1),
                      createFace(2),
                      createFace(3),
                      createFace(4),
                      createFace(5),
                      createFace(6),
                      createFace(7),
                      createFace(8),
                      createFace(9),
                    ],
                    itemExtent: 55.0,
                    onSelectedItemChanged: (int newValue) {
                      setState(() {
                        num = newValue;
                      });
                      //print("Controller value: ${controller.selectedItem}");
                    },
                    onDetentEnter: () {
                      //print("Dentent Enter");
                    },
                    onDetentExit: () {
                      //print("Dentent Exit");
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
