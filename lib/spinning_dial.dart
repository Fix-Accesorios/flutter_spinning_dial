import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

class SpinningDial extends StatefulWidget {
  final List<Widget> sides;

  SpinningDial({Key key, this.sides}) : super(key: key); // changed

  @override
  _SpinningDialState createState() => _SpinningDialState();
}

class _SpinningDialState extends State<SpinningDial> {
  double _angle = 0;
  double _widgetHeight = 75.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // new
      onPanUpdate: (details) => setState(() =>
          _angle = (_angle + calculateRadianDelta(details.delta)) % (2 * pi)),
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
    );
  }

  double calculateRadianDelta(Offset offset) {
    double angleDelta = -0.5 * (offset.dy);
    double radDelta = angleDelta * pi / 180;

    return radDelta;
  }

  List<Widget> constructStack(int sides, double currentAngle) {
    //determine starting point
    var sliceAngle = 2 * pi / sides;
    var frontSide = 0;
    for (var i = sliceAngle; i < 2 * pi; i += sliceAngle) {
      if (currentAngle < i) {
        break;
      }
      frontSide++;
    }
    if (frontSide >= sides) frontSide = sides - 1;

    print('frontSide: $frontSide    currentAngle: $currentAngle');

    var ints = new List<int>(sides);

    var up = frontSide + 1 < sides ? frontSide + 1 : 0;
    var down = frontSide;

    for (var i = 0; i < sides - 1; i += 2) {
      ints[i] = down;
      ints[i + 1] = up;

      up = up + 1 < sides ? up + 1 : 0;
      down = down - 1 >= 0 ? down - 1 : sides - 1;
    }

    return ints.reversed
        .map((int index) =>
            createSide(_widgetHeight, currentAngle, sides, index))
        .toList();
  }

  Widget createSide(
      double sideHeight, double currentAngle, int sides, int index) {
    return Transform(
      key: Key((index + 1).toString()),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..translate(calculateOffset(currentAngle, sideHeight, sides, index))
        ..rotateX(calculateSideRotationAngle(currentAngle, sides, index)),
      alignment: Alignment.center,
      child: this.widget.sides[index],
    );
  }

  double calculateSideRotationAngle(double rads, int sides, int index) {
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
}
