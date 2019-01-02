import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as Vectors;

class SpinningDialView extends StatefulWidget {
  SpinningDialView({
    Key key,
    this.controller,
    @required this.itemExtent,
    this.onSelectedItemChanged,
    @required this.children,
    this.axis = Axis.horizontal,
    this.detent = 1.00,
    this.onDetentEnter,
    this.onDetentExit,
  })  : assert(children != null),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        super(key: key);

  /// Typically a [DialController] used to control the current item.
  ///
  /// A [DialController] can be used to read the currently
  /// selected/centered child item and can be used to change the current item.
  ///
  /// If none is provided, a new [DialController] is implicitly
  /// created.
  ///
  /// To read the current selected item only when the value changes, use
  /// [onSelectedItemChanged].
  final DialController controller;

  /// Size of each child in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// On optional listener that's called when the centered item changes.
  final ValueChanged<int> onSelectedItemChanged;

  //Called when the dial enters a detent
  final Function onDetentEnter;

  //Called when the dial exits the detent
  final Function onDetentExit;

  /// A list of the child faces.
  final List<Widget> children;

  /// Define a main axis of scrolling
  final Axis axis;

  ///Percentange of the side that is part of detent.
  ///
  ///The detent is where the settle occurs
  final double detent;

  @override
  _SpinningDialViewState createState() => _SpinningDialViewState();
}

class _SpinningDialViewState extends State<SpinningDialView>
    with TickerProviderStateMixin {
  double _currentAngle = 0;
  RegularPolygon polygon;
  DialController dialController;
  DialPosition position;

  @override
  void initState() {
    super.initState();
    polygon = RegularPolygon(widget.children.length, widget.itemExtent);

    dialController = widget.controller ??
        DialController(DialPosition(this, polygon), polygon)
      ..addListener(() {
        setState(() {
          print("DialPosition changed");
          _currentAngle = dialController.position.currentAngle;
        });
      });
  }

  @override
  void dispose() {
    dialController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // new
      onVerticalDragUpdate: (details) =>
          dialController.moveOffset(details.delta.dy),
      onVerticalDragEnd: (details) =>
          dialController.moveEnd(details.primaryVelocity),
      behavior: HitTestBehavior.deferToChild,
      child: Stack(
        children: constructStack(_currentAngle),
      ),
    );
  }

  List<Widget> constructStack(double currentAngle) {
    var sides = generatePaintOrder();
    sides = removeNonpaintedSides(currentAngle, sides);
    return sides.reversed
        .map((int index) => createSide(currentAngle, index))
        .toList();
  }

  List<int> generatePaintOrder() {
    var sideCount = polygon.sides;
    var frontSide = dialController.selectedItem;

    var sides = new List<int>(sideCount);
    var up = frontSide + 1 < sideCount ? frontSide + 1 : 0;
    var down = frontSide;

    for (var i = 0; i < sideCount; i += 2) {
      sides[i] = down;
      if (i != sideCount - 1) {
        sides[i + 1] = up;
      }

      up = up + 1 < sideCount ? up + 1 : 0;
      down = down - 1 >= 0 ? down - 1 : sideCount - 1;
    }
    return sides;
  }

  List<int> removeNonpaintedSides(double currentAngle, List<int> sides) {
    List<int> finalList = List<int>.from(sides);

    for (var i in sides) {
      var axisAngle = calculateRotationOffset(currentAngle, i);
      if (axisAngle < 0) {
        axisAngle = 2 * pi + axisAngle;
      }
      if (axisAngle > pi / 2 && axisAngle < 3 * pi / 2) {
        finalList.remove(i);
      }
    }
    print("finalList: $finalList");
    return finalList;
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

class DialController extends ChangeNotifier {
  DialController(this.position, this.polygon, {this.onSelectedItemChanged})
      : super() {
    position.addListener(() {
      positionChanged();
    });
  }

  final RegularPolygon polygon;
  DialPosition position;
  int _previousSelectedItem;
  final ValueChanged<int> onSelectedItemChanged;

@override 
void dispose(){
  position.dispose();
  super.dispose();
}
  int get selectedItem {
    var frontIndex = 0;
    var sides = polygon.sides;
    //If it is the first side, we will skip the for loop
    if (position.currentAngle < (sides * 2 - 1) * pi / sides &&
        position.currentAngle >= pi / sides) {
      for (var i = 1; i < (sides * 2) - 1; i = i + 2) {
        frontIndex++;
        if (position.currentAngle > i * pi / sides &&
            position.currentAngle < (i + 2) * pi / sides) {
          return frontIndex;
        }
      }
    }
    return frontIndex;
  }

  void positionChanged() {
    print('positionChanged');
    notifyListeners();
    var frontIndex = selectedItem;

    if (frontIndex != _previousSelectedItem) {
      if (onSelectedItemChanged != null) {
        onSelectedItemChanged(frontIndex);
      }
      _previousSelectedItem = frontIndex;
    }
  }

  // DialPosition createDialPosition(TickerProvider context) {
  //   return DialPosition(context, polygon);
  // }

  void moveOffset(double linearDelta) {
    position.moveOffset(linearDelta);
  }

  void moveEnd(double linearVelocity) {
    position.moveEnd(linearVelocity);
  }
}

class DialPosition extends ValueNotifier<double> {
  AnimationController physicsController;
  AnimationController settleController;
  Animation settleAnimation;
  final RegularPolygon polygon;
  final double detent;
  final Function onDetentEnter;
  final Function onDetentExit;
  bool isInDetent = true;

  DialPosition(TickerProvider state, this.polygon,
      {this.detent = 1.00,
      this.onDetentEnter,
      this.onDetentExit,
      double initialPosition})
      : super(initialPosition ?? 0.0) {
    physicsController = AnimationController(
      duration: const Duration(
        milliseconds: 100,
      ),
      vsync: state,
      upperBound: double.infinity,
      lowerBound: double.negativeInfinity,
    )..addListener(() {
        currentAngle = physicsController.value % 2 * pi;
      });

    settleController = AnimationController(
      duration: const Duration(
        milliseconds: 300,
      ),
      vsync: state,
    );

    settleAnimation = settleController.drive(
        Tween()) //We will replace this animation when it is time to animate
      ..addListener(() {
        if (settleAnimation.value != null) {
          currentAngle = settleAnimation.value;
        }
      });
  }

  @override
  void dispose(){
    physicsController.dispose();
    settleController.dispose();
    super.dispose();
  }
  double get currentAngle => value;

  set currentAngle(double newAngle) {
    checkDetent(newAngle);
    print("angle changed: $newAngle");
    value = newAngle;
  }

  void moveOffset(double linearDelta) {
    print("moveOffset: $linearDelta");
    physicsController.stop();
    var rotationalDelta = calculateRotationalDelta(linearDelta);
    var absoluteAngle = (currentAngle + rotationalDelta) % (2 * pi);

    currentAngle = absoluteAngle;
  }

  void moveEnd(double linearVelocity) {
    print("moveEnd: $linearVelocity");
    if (linearVelocity.abs() > 1) {
      FrictionSimulation sim = FrictionSimulation(
          0.05, currentAngle, linearVelocity / -200,
          tolerance: Tolerance(velocity: 0.1));
      print(linearVelocity / -100);
      physicsController.animateWith(sim).then((_) {
        animateDetentSettle();
      });
    } else {
      animateDetentSettle();
    }
  }

  void animateDetentSettle() {
    print("animating detent settle");
    var currentDetentAngle = detentAngle(detent);
    if (!currentDetentAngle.isNaN) {
      if (currentDetentAngle == 0 && currentAngle > pi) {
        currentDetentAngle = 2 * pi;
      }
      final CurvedAnimation curve = CurvedAnimation(
        parent: settleController,
        curve: Curves.ease,
      );
      settleAnimation = curve.drive(Tween(
        begin: currentAngle,
        end: currentDetentAngle,
      ));
      settleController.forward(from: 0.0);
    }
  }

  double detentAngle(double detentPercent) {
    var frontSideAngle = selectedItem * 2 * pi / polygon.sides;
    var detentOffset = polygon.exteriorAngle * detentPercent / 2;

    var positiveOffset = frontSideAngle + detentOffset;
    var negativeOffset = frontSideAngle - detentOffset;
    if (negativeOffset < 0 || positiveOffset > 2 * pi) {
      if (negativeOffset < 0) {
        negativeOffset = 2 * pi - negativeOffset.abs();
      }
      if (positiveOffset > 2 * pi) {
        positiveOffset = positiveOffset - 2 * pi;
      }
      if ((currentAngle > negativeOffset) || (currentAngle < positiveOffset)) {
        return frontSideAngle;
      }
    }
    if ((currentAngle > negativeOffset) && (currentAngle < positiveOffset)) {
      return frontSideAngle;
    }
    return double.nan;
  }

  int get selectedItem {
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

  void checkDetent(double currentAngle) {
    if (!isInDetent && !detentAngle(detent).isNaN) {
      print('click');
      if (onDetentEnter != null) {
        onDetentEnter();
      }
    }
    if (isInDetent && detentAngle(detent).isNaN) {
      isInDetent = false;
      if (onDetentExit != null) {
        onDetentExit();
      }
    }
  }

  double calculateRotationalDelta(double linearDelta) {
    double angleDelta = -0.5 * (linearDelta);
    double radDelta = angleDelta * pi / 180;

    return radDelta;
  }
}

/// Based on regular polygon definitions found here: https://www.mathsisfun.com/geometry/regular-polygons.html
/// Provides math for regular polygons given a side length and side count
@immutable
class RegularPolygon {
  ///Defines the number of sides of the polygon.
  final int sides;
  final double sideLength;

  RegularPolygon(this.sides, this.sideLength)
      : assert(sides > 0),
        assert(sideLength > 0);

  //Angle between two lines that connect to both vertices of a side
  double get exteriorAngle => pi - interiorAngle;

  //Angle between two adjacent sides
  double get interiorAngle => pi * (sides - 2) / sides;

  //Distance from polygon center to middle of a side
  double get apothem => sideLength / (2 * tan(pi / sides));

  //Distance from polygon center to vertex
  double get radius => sideLength / (2 * sin(pi / sides));
}
