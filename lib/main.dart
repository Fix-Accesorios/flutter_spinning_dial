import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

void main() => runApp(MyApp());

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
  double _angle = 0;
  double _widgetHeight = 75.0;
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: GestureDetector(
        // new
        onPanUpdate: (details) =>
            setState(() => _angle += calculateAngleDelta(details.delta)),
        onDoubleTap: () => setState(() => _angle = 0),
        behavior: HitTestBehavior.deferToChild,
        child: Container(
          color: Colors.green,
          child: Padding(
            padding: const EdgeInsets.only(top: 180.0),
            child: Stack(
              children: constructStack(6, _angle),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> constructStack(int sides, double rads) {
    //determine starting point
    var sliceAngle = 2 * pi / sides;
    var index = 1;
    var angle = rads % (2 * pi);
    for (var i = sliceAngle; i < 2 * pi; i += sliceAngle) {
      if (angle < i) {
        break;
      }
      index++;
    }
    if (index > sides) index = sides;

    print('index: $index    rads: $rads    absAngle: $angle');

    var ints = new List<int>(sides);

    var up = index + 1 <= sides ? index + 1 : 1;
    var down = index;

    for (var i = 0; i < sides; i += 2) {
      ints[i] = down;
      ints[i + 1] = up;

      up = up + 1 <= sides ? up + 1 : 1;
      down = down - 1 > 0 ? down - 1 : sides;
    }

    return ints.reversed
        .map((int f) => createSide(
            f.toString(), colors[f - 1], _widgetHeight, _angle, sides, f - 1))
        .toList();
  }

  double calculateAngleDelta(Offset offset) {
    double angleDelta = -0.5 * (offset.dy);
    double radDelta = angleDelta * pi / 180;

    return radDelta;
  }

  double calculateAngle(double rads, int sides, int index) {
    var angle = 2 * pi / sides;
    var angleOffset = index * angle;

    var sideAngle = -1 * (rads - angleOffset);

    return sideAngle;
  }

  Vectors.Vector3 calculateOffset(
      double rads, double sideHeight, int sides, int index) {
    //Calculate the angle of each "pizza slice" by dividing 360 degrees by the number of "slices"
    var angle = 2 * pi / sides;

    //the adjacent leg of the triangle is half of the side height. The opposite leg of the triangle will be the radius
    var radius = tan(angle) * (sideHeight / 2);

    var angleOffset = index * angle;

    var indexedAngle = rads - angleOffset;

    double y = -1 * sin(indexedAngle) * radius;
    double z = -1 * cos(indexedAngle) * radius;

    //print('Index: $index   y:$y    z:$z');
    return new Vectors.Vector3(0, y, z);
  }

  Widget createSide(String num, Color color, double sideHeight, double angle,
      int sides, int index) {
    return Transform(
      key: Key(num),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..translate(calculateOffset(_angle, sideHeight, sides, index))
        ..rotateX(calculateAngle(_angle, sides, index)),
      alignment: Alignment.center,
      child: createFace(num, color),
    );
  }

  Widget createFace(String num, Color color) {
    return ClipRect(
      key: Key(num),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          key: Key(num),
          color: color,
          padding: EdgeInsets.all(20.0),
          child: Text(
            num,
            key: Key(num),
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.0,
            ),
          ),
        ),
      ),
    );
  }
}
