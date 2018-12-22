import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

enum Detent { none, small, medium, large }

class SpinningDialView extends StatefulWidget {
  //this.detent = 1.00, -> need to add this to physics
  //final double detent;

  SpinningDialView({
    Key key,
    this.controller,
    this.physics,
    @required this.itemExtent,
    this.onSelectedItemChanged,
    @required this.children,
    this.axis = Axis.horizontal,
  })  : assert(children != null),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        super(key: key);


  /// Typically a [FixedExtentScrollController] used to control the current item.
  ///
  /// A [FixedExtentScrollController] can be used to read the currently
  /// selected/centered child item and can be used to change the current item.
  ///
  /// If none is provided, a new [FixedExtentScrollController] is implicitly
  /// created.
  ///
  /// If a [ScrollController] is used instead of [FixedExtentScrollController],
  /// [ScrollNotification.metrics] will no longer provide [FixedExtentMetrics]
  /// to indicate the current item index and [onSelectedItemChanged] will not
  /// work.
  ///
  /// To read the current selected item only when the value changes, use
  /// [onSelectedItemChanged].
  final ScrollController controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// Size of each child in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// On optional listener that's called when the centered item changes.
  final ValueChanged<int> onSelectedItemChanged;

  /// A list of the child faces.
  final List<Widget> children;

  /// Define a main axis of scrolling
  final Axis axis;

  @override
  _SpinningDialViewState createState() => _SpinningDialViewState();
}

class _SpinningDialViewState extends State<SpinningDialView>
    with TickerProviderStateMixin {
  double _currentAngle = 0;
  int _currentFrontIndex = 0;
  AnimationController physicsController;
  AnimationController settleController;
  Animation<double> animation;
  static AudioCache player = new AudioCache();
  RegularPolygon polygon;
  bool isInDetent = true;

  @override
  void initState() {
    super.initState();
    polygon = RegularPolygon(widget.children.length, widget.itemExtent);
    physicsController = AnimationController(
      duration: const Duration(
        milliseconds: 100,
      ),
      vsync: this,
      upperBound: double.infinity,
      lowerBound: double.negativeInfinity,
    )..addListener(() {
        setState(() {
          var animated = physicsController.value;
          //print("animationValue: $animated    currentAngle: $_currentAngle");
          _currentAngle = animated % 2 * pi;
        });
      });
    settleController = AnimationController(
      duration: const Duration(
        milliseconds: 300,
      ),
      vsync: this,
    );

    animation = settleController.drive(
        Tween()) //We will replace this animation when it is time to animate
      ..addListener(() {
        setState(() {
          if (animation.value != null) {
            var animated = animation.value;
            //print("animationValue: $animated    currentAngle: $_currentAngle");
            _currentAngle = animated;
          }
        });
      });
  }

  @override
  void dispose() {
    physicsController.dispose();
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
    physicsController.stop();
    var rotationalDelta = calculateRotationalDelta(linearDelta);
    var absoluteAngle = (_currentAngle + rotationalDelta) % (2 * pi);

    setState(() => _currentAngle = absoluteAngle);
  }

  void handleOnDragEnd(DragEndDetails details) {
    if (details.primaryVelocity.abs() > 1) {
      var sims = ClampingScrollSimulation(
          position: _currentAngle,
          velocity: details.primaryVelocity / -90,
          friction: 0.1,
          tolerance: Tolerance(velocity: 0.1));
      FrictionSimulation sim = FrictionSimulation(
          0.05, _currentAngle, details.primaryVelocity / -200,
          tolerance: Tolerance(velocity: 0.1));
      print(details.primaryVelocity / -100);
      physicsController.animateWith(sims).then((_) {
        //animateDetentSettle();
      });
    } else {
      animateDetentSettle();
    }
  }

  void animateDetentSettle() {
    var currentDetentAngle = detentAngle(widget.detent);
    if (!currentDetentAngle.isNaN) {
      if (currentDetentAngle == 0 && _currentAngle > pi) {
        currentDetentAngle = 2 * pi;
      }
      final CurvedAnimation curve = CurvedAnimation(
        parent: settleController,
        curve: Curves.ease,
      );
      animation = curve.drive(Tween(
        begin: _currentAngle,
        end: currentDetentAngle,
      ));
      settleController.forward(from: 0.0);
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
    if (!isInDetent && !detentAngle(0.3).isNaN) {
      print('click');
      player.play("clamp_2.mp3", volume: 0.2);
      isInDetent = true;
    }
    if (isInDetent && detentAngle(0.3).isNaN) {
      isInDetent = false;
      print('unclick');
    }
  }

  List<Widget> constructStack(double currentAngle) {
    var sides = polygon.sides;
    //determine starting point
    var frontIndex = determineFrontSide(currentAngle);
    if (frontIndex != _currentFrontIndex) {
      widget.onSelectedItemChanged(frontIndex);
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
      child: this.widget.children[index],
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
