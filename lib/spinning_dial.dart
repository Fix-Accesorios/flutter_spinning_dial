import 'dart:ui';
//import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

enum Detent { none, small, medium, large }

class SpinningDial extends StatefulWidget {
  final List<Widget> sides;
  final double sideLength;
  final double detent;
  final ValueChanged<int> onChanged;

  SpinningDial(
      {Key key,
      @required this.sides,
      @required this.sideLength,
      this.detent = 1.00,
      @required this.onChanged})
      : super(key: key);

  @override
  _SpinningDialState createState() => _SpinningDialState();
}

class _SpinningDialState extends State<SpinningDial>
    with TickerProviderStateMixin {
  double _currentAngle = 0;
  int _currentFrontIndex = 0;
  AnimationController positionController;
  Animation<double> animation;

  //static AudioCache player = new AudioCache();
  RegularPolygon polygon;
  bool isInDetent = true;

  @override
  void initState() {
    super.initState();
    polygon = RegularPolygon(widget.sides.length, widget.sideLength);
    positionController = AnimationController(
      duration: const Duration(
        milliseconds: 100,
      ),
      vsync: this,
    );
    animation = positionController.drive(Tween())//We will replace this animation when it is time to animate
      ..addListener(() {
        setState(() {
          var animated = animation.value;
          print("animationValue: $animated    currentAngle: $_currentAngle");
          _currentAngle = animated;
        });
      });
  }

  @override
  void dispose() {
    positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // new
      onVerticalDragUpdate: (details) => handleOnDragUpdate(details.delta.dy),
      onVerticalDragEnd: (details) => handleOnDragEnd(details),
      behavior: HitTestBehavior.deferToChild,
      child: Stack(
        children: constructStack(_currentAngle),
      ),
    );
  }

  void handleOnDragUpdate(double linearDelta) {
    positionController.stop();
    var rotationalDelta = calculateRotationalDelta(linearDelta);
    var absoluteAngle = (_currentAngle + rotationalDelta) % (2 * pi);

    setState(() => _currentAngle = absoluteAngle);
  }

  void handleOnDragEnd(DragEndDetails details) 
  {
    animateDetentSettle();
  }

  void animateDetentSettle() {
    var currentDetentAngle = detentAngle(widget.detent);
    if (!currentDetentAngle.isNaN) {
      if (currentDetentAngle == 0 && _currentAngle > pi) {
        currentDetentAngle = 2 * pi;
      }
      final CurvedAnimation curve =
          CurvedAnimation(parent: positionController, curve: Curves.bounceOut);
      animation =
          curve.drive(Tween(begin: _currentAngle, end: currentDetentAngle));
      positionController.forward(from: 0.0);
    }
  }

  double calculateRotationalDelta(double linearDelta) {
    double angleDelta = -0.5 * (linearDelta);
    double radDelta = angleDelta * pi / 180;

    return radDelta;
  }

  double detentAngle(double percent) {
    var frontSideAngle = _currentFrontIndex * 2 * pi / polygon.sides;
    var detentOffset = polygon.exteriorAngle * percent / 2;

    var positiveOffset = frontSideAngle + detentOffset;
    var negativeOffset = frontSideAngle - detentOffset;
    if (negativeOffset < 0 || positiveOffset > 2 * pi) {
      if (negativeOffset < 0) {
        negativeOffset = 2 * pi - negativeOffset.abs();
      }
      if (positiveOffset > 2 * pi) {
        positiveOffset = positiveOffset - 2 * pi;
      }
      if ((_currentAngle > negativeOffset) ||
          (_currentAngle < positiveOffset)) {
        return frontSideAngle;
      }
    }
    if ((_currentAngle > negativeOffset) && (_currentAngle < positiveOffset)) {
      return frontSideAngle;
    }
    return double.nan;
  }

  void doClick(double currentAngle) {
    if (!isInDetent && !detentAngle(0.1).isNaN) {
      print('click');
      //player.play("assets/click.mp3");
      isInDetent = true;
    }
    if (isInDetent && detentAngle(0.1).isNaN) {
      isInDetent = false;
      print('unclick');
    }
  }

  List<Widget> constructStack(double currentAngle) {
    var sides = polygon.sides;
    //determine starting point
    var frontIndex = determineFrontSide(currentAngle);
    if (frontIndex != _currentFrontIndex) {
      widget.onChanged(frontIndex);
      _currentFrontIndex = frontIndex;
    }
    doClick(currentAngle);
    //print('frontSide: $frontIndex    currentAngle: $currentAngle');

    var ints = new List<int>(sides);
    var up = frontIndex + 1 < sides ? frontIndex + 1 : 0;
    var down = frontIndex;

    for (var i = 0; i < sides; i += 2) {
      ints[i] = down;
      if (i != sides - 1) ints[i + 1] = up;

      up = up + 1 < sides ? up + 1 : 0;
      down = down - 1 >= 0 ? down - 1 : sides - 1;
    }

    return ints.reversed
        .map((int index) => createSide(currentAngle, index))
        .toList();
  }

  int determineFrontSide(double currentAngle) {
    //determine starting point
    var frontIndex = 0;
    var sides = polygon.sides;
    //If it is the first side, we will skip the for loop
    if (currentAngle < (sides * 2 - 1) * pi / sides &&
        currentAngle >= pi / sides) {
      for (var i = 1; i < (sides * 2) - 1; i = i + 2) {
        frontIndex++;
        if (currentAngle > i * pi / sides &&
            currentAngle < (i + 2) * pi / sides) {
          return frontIndex;
        }
      }
    }

    return frontIndex;
  }

  Widget createSide(double currentAngle, int index) {
    return Transform(
      key: Key((index + 1).toString()),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..translate(calculateLinearOffset(currentAngle, index))
        ..rotateX(calculateRotationOffset(currentAngle, index)),
      alignment: Alignment.center,
      child: this.widget.sides[index],
    );
  }

  double calculateRotationOffset(double currentAngle, int index) {
    return -1 * (currentAngle - index * polygon.exteriorAngle);
  }

  Vectors.Vector3 calculateLinearOffset(double currentAngle, int index) {
    //Represents the angle of the apothem of this specific side from 0.0
    var indexedAngle = currentAngle - index * polygon.exteriorAngle;

    double y = -1 * sin(indexedAngle) * polygon.apothem;
    double z = -1 * cos(indexedAngle) * polygon.apothem;

    return new Vectors.Vector3(0, y, z);
  }
}

/// Based on regular polygon definitions found here: https://www.mathsisfun.com/geometry/regular-polygons.html
///
class RegularPolygon {
  final int sides;
  final double sideLength;

  //Angle between two lines that connect to vertices of a side
  double exteriorAngle;

  //Angle between two connected sides
  double interiorAngle;

  //Distance to middle of side
  double apothem;

//distance to vertex
  double radius;

  RegularPolygon(this.sides, this.sideLength) {
    interiorAngle = pi * (sides - 2) / sides;
    exteriorAngle = pi - interiorAngle;

    apothem = sideLength / (2 * tan(pi / sides));
    radius = sideLength / (2 * sin(pi / sides));
  }
}
