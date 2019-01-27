import 'package:flutter/material.dart';

import 'spinning_dial.dart';

void main() => runApp(MyApp());

Widget createFace(int index) {
  var key = (index + 1).toString();

  return ClipRect(
    key: Key(key),
    child: Align(
      alignment: Alignment.center,
      child: Container(
        key: Key(key),
        color: Colors.blue[100 * (index + 1)],
        padding: EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 30.0),
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
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 180),
        color: Colors.blueGrey,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom:20.0),
              child: Text(
                (num + 1).toString(),
                style: TextStyle(fontSize: 24.0),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SpinningDialView(
                  detent: 1.0,
                  children: <Widget>[
                    createFace(0),
                    createFace(1),
                    createFace(2),
                    createFace(3),
                    createFace(4),
                    createFace(5),
                    createFace(6),
                    createFace(7),
                  ],
                  itemExtent: 83.0,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
