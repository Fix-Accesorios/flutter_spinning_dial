import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

enum Detent { none, small, medium, large }

class SpinningDial extends StatefulWidget {
  final List<Widget> sides;
  final double sideHeight;
  final Detent detent;
  final ValueChanged<int> onChanged;

  SpinningDial(
      {Key key,
      @required this.sides,
      @required this.sideHeight,
      this.detent = Detent.medium,
      @required this.onChanged})
      : super(key: key); // changed

  @override
  _SpinningDialState createState() => _SpinningDialState();
}

class _SpinningDialState extends State<SpinningDial> with TickerProviderStateMixin {
  double _angle = 0;
  int _currentFrontIndex = 0;
AnimationController positionController;

 @override
  void initState() {
    super.initState();
    positionController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // new
      onPanUpdate: (details) => handleOnPanUpdate(details),
      onPanEnd: (details) => handleOnPanEnd(details),
      onDoubleTap: () => setState(() => _angle = 0),
      behavior: HitTestBehavior.deferToChild,
      child: Stack(
        children: constructStack(widget.sides.length, _angle),
      ),
    );
  }

  void handleOnPanUpdate(DragUpdateDetails details) {
    setState(() =>
        _angle = (_angle + calculateRadianDelta(details.delta)) % (2 * pi));
  }

  handleOnPanEnd(DragEndDetails details) {
    
  }

  double calculateRadianDelta(Offset offset) {
    double angleDelta = -0.5 * (offset.dy);
    double radDelta = angleDelta * pi / 180;

    return radDelta;
  }

  List<Widget> constructStack(int sideCount, double currentAngle) {
    //determine starting point
    var frontIndex = determineFrontSide(sideCount, currentAngle);
    if (frontIndex != _currentFrontIndex) {
      widget.onChanged(frontIndex);
      _currentFrontIndex = frontIndex;
    }
    //print('frontSide: $frontIndex    currentAngle: $currentAngle');

    var ints = new List<int>(sideCount);
    var up = frontIndex + 1 < sideCount ? frontIndex + 1 : 0;
    var down = frontIndex;

    for (var i = 0; i < sideCount; i += 2) {
      ints[i] = down;
      if (i != sideCount - 1) ints[i + 1] = up;

      up = up + 1 < sideCount ? up + 1 : 0;
      down = down - 1 >= 0 ? down - 1 : sideCount - 1;
    }

    return ints.reversed
        .map((int index) =>
            createSide(this.widget.sideHeight, currentAngle, sideCount, index))
        .toList();
  }

  int determineFrontSide(int sideCount, double currentAngle) {
    //determine starting point
    var frontIndex = 0;

    //If it is the first side, we will skip the for loop
    if (currentAngle < (sideCount * 2 - 1) * pi / sideCount &&
        currentAngle >= pi / sideCount) {
      for (var i = 1; i < (sideCount * 2) - 1; i = i + 2) {
        frontIndex++;
        if (currentAngle > i * pi / sideCount &&
            currentAngle < (i + 2) * pi / sideCount) {
          return frontIndex;
        }
      }
    }

    return frontIndex;
  }

  Widget createSide(
      double sideHeight, double currentAngle, int sideCount, int index) {
    return Transform(
      key: Key((index + 1).toString()),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..translate(calculateOffset(currentAngle, sideHeight, sideCount, index))
        ..rotateX(calculateSideRotationAngle(currentAngle, sideCount, index)),
      alignment: Alignment.center,
      child: this.widget.sides[index],
    );
  }

  double calculateSideRotationAngle(double rads, int sideCount, int index) {
    var angle = 2 * pi / sideCount;
    var angleOffset = index * angle;

    var sideAngle = -1 * (rads - angleOffset);

    return sideAngle;
  }

  Vectors.Vector3 calculateOffset(
      double rads, double sideHeight, int sideCount, int index) {
    //Calculate the angle of each "pizza slice" by dividing 360 degrees by the number of "slices"
    var angle = 2 * pi / sideCount;
    var legAngle = pi - pi / 2 - angle / 2;

    //the adjacent leg of the triangle is half of the side height. The opposite leg of the triangle will be the radius
    var radius = tan(legAngle) * (sideHeight / 2);

    var angleOffset = index * angle;

    var indexedAngle = rads - angleOffset;

    double y = -1 * sin(indexedAngle) * radius;
    double z = -1 * cos(indexedAngle) * radius;

    //print('Index: $index   y:$y    z:$z');
    return new Vectors.Vector3(0, y, z);
  }

}
