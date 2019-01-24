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
  RegularPolygon _polygon;
  DialController dialController;
  DialPosition _position;
  int _previousStateItemIndex = 0;
  bool _previousStateIsInDetent = true;

  @override
  void initState() {
    super.initState();
    _polygon = RegularPolygon(widget.children.length, widget.itemExtent);

    dialController = widget.controller ?? DialController();
    if (dialController.position == null) {
      _position = dialController.createDialPosition(
        this,
        _polygon,
        detentPercent: widget.detent,
      );
      dialController.attach(_position);
    }

    dialController.addListener(() {
      _updateDialPosition(dialController.position.currentAngle);
      setState(() {
        _currentAngle = dialController.position.currentAngle;
      });
    });
  }

  @override
  void didUpdateWidget(SpinningDialView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _polygon = RegularPolygon(widget.children.length, widget.itemExtent);
    _position.polygon = _polygon;
    _position.detent = widget.detent;
  }

  @override
  void dispose() {
    dialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // new
      onVerticalDragUpdate: (details) =>
          dialController.moveOffset(details.delta.dy),
      onVerticalDragEnd: (details) =>
          dialController.moveEnd(details.primaryVelocity),
      child: Container(
        height: _polygon.radius * 2,
        child: Stack(
          children: constructStack(_currentAngle),
        ),
      ),
    );
  }

  void _updateDialPosition(double newAngle) {
    //print("_currentAngle: $newAngle");
    //Determine which item is facing forward
    var currentStateItemIndex = _position.itemIndex;
    //print("currentStateItemIndex: $currentStateItemIndex");

    //Determine if dial forward item changed
    var currentItemIndexChanged =
        _position.itemIndex != _previousStateItemIndex;
    //print("currentItemIndexChanged: $currentItemIndexChanged");

    //Determine if dial is in detent on front item
    var currentStateIsInDetent = _position.isInDetent();
    //print("currentStateIsInDetent: $currentStateIsInDetent");

    //Determine if dial left the previous detent. This will either be because
    //the dial was in a detent and it no longer is, or it is in detent
    //but the item index changed (this happens if detentPercent is 1.0).
    var exitedDetent = (!currentStateIsInDetent && _previousStateIsInDetent) ||
        (currentStateIsInDetent && currentItemIndexChanged);
    //print("exitedDetent: $exitedDetent");

    //Determine if dial entered the current detent. This will either be because the
    //dial was not in a detent and now it is, or it was in a detent by the item
    //index changed (this happens is detentPercent is 1.0)
    var enteredDetent = (currentStateIsInDetent && !_previousStateIsInDetent) ||
        (_previousStateIsInDetent && currentItemIndexChanged);
    //print("enteredDetent: $enteredDetent");

    if (currentItemIndexChanged && widget.onSelectedItemChanged != null) {
      widget.onSelectedItemChanged(_position.itemIndex);
    }

    if (exitedDetent && widget.onDetentExit != null) {
      widget.onDetentExit();
    }

    if (enteredDetent && widget.onDetentEnter != null) {
      widget.onDetentEnter();
    }

    _previousStateItemIndex = currentStateItemIndex;

    _previousStateIsInDetent = currentStateIsInDetent;
  }

  List<Widget> constructStack(double currentAngle) {
    var sides = generatePaintOrder();
    sides = removeNonpaintedSides(currentAngle, sides);
    return sides.reversed
        .map((int index) => createSide(currentAngle, index))
        .toList();
  }

  List<int> generatePaintOrder() {
    var sideCount = _polygon.sides;
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
    return finalList;
  }

  Widget createSide(double currentAngle, int index) {
    return Transform(
      key: Key((index + 1).toString()),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00001) // perspective
        ..translate(calculateLinearOffset(currentAngle, index))
        ..rotateX(calculateRotationOffset(currentAngle, index)),
      alignment: Alignment.center,
      child: this.widget.children[index],
    );
  }

  double calculateRotationOffset(double currentAngle, int index) {
    return -1 * (currentAngle - index * _polygon.exteriorAngle);
  }

  Vectors.Vector3 calculateLinearOffset(double currentAngle, int index) {
    //Represents the angle of the apothem of this specific side from 0.0
    var indexedAngle = currentAngle - index * _polygon.exteriorAngle;

    double y = -1 * sin(indexedAngle) * _polygon.apothem;
    double z = -1 * cos(indexedAngle) * _polygon.apothem;

    return new Vectors.Vector3(0, y, z);
  }
}

class DialController extends ChangeNotifier {
  DialController() : super();

  DialPosition _position;
  DialPosition get position => _position;
  int _previousSelectedItem;

  @override
  void dispose() {
    super.dispose();
  }

  void attach(DialPosition dialPosition) {
    _position = dialPosition;
    _position.addListener(() {
      positionChanged();
    });
  }

  void detach(DialPosition dialPosition) {
    _position = dialPosition;
    _position.addListener(() {
      positionChanged();
    });
  }

  int get selectedItem {
    return _position != null ? _position.itemIndex : null;
  }

  void positionChanged() {
    notifyListeners();
    var frontIndex = selectedItem;

    if (frontIndex != _previousSelectedItem) {
      _previousSelectedItem = frontIndex;
    }
  }

  DialPosition createDialPosition(
    TickerProvider context,
    RegularPolygon polygon, {
    double detentPercent = 1.0,
  }) {
    return DialPosition(
      context,
      polygon,
      detent: detentPercent,
    );
  }

  void moveOffset(double linearDelta) {
    _position.handleDragUpdate(linearDelta);
  }

  void moveEnd(double linearVelocity) {
    _position.hangleDragEnd(linearVelocity);
  }
}

class DialPosition extends ValueNotifier<double> {
  AnimationController physicsController;
  AnimationController settleController;
  Animation settleAnimation;
  RegularPolygon polygon;
  double detent;
  bool _previousStateIsInDetent = true;
  int _previousStateItemIndex = 0;

  DialPosition(
    TickerProvider state,
    this.polygon, {
    this.detent = 1.00,
    double initialPosition,
  }) : super(initialPosition ?? 0.0) {
    physicsController = AnimationController(
      duration: const Duration(
        milliseconds: 100,
      ),
      vsync: state,
      upperBound: double.infinity,
      lowerBound: double.negativeInfinity,
    )..addListener(() {
        currentAngle = physicsController.value % (2 * pi);
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
  void dispose() {
    physicsController.dispose();
    settleController.dispose();
    super.dispose();
  }

  /// The angle of the polygon that is pointing directly towards the screen.
  double get currentAngle => value;

  /// The angle of the polygon that is pointing directly towards the screen.
  set currentAngle(double newAngle) {
    value = newAngle;
  }

  ///The item that is facing towards the user
  int get itemIndex {
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

  void handleDragUpdate(double linearDelta) {
    //print("*******************moveOffset: $linearDelta");
    var rotationalDelta = calculateAngularDelta(linearDelta) *
        -1; //drag is opposite direction of movement on screen
    var absoluteAngle = (currentAngle + rotationalDelta) % (2 * pi);

    currentAngle = absoluteAngle;
  }

  void hangleDragEnd(double linearVelocity) {
    //print("*******************moveEnd: $linearVelocity");
    if (linearVelocity.abs() > 200) {
      FrictionSimulation sim = FrictionSimulation(
          0.05, currentAngle, linearVelocity / -200,
          tolerance: Tolerance(velocity: 1));
      physicsController.animateWith(sim).then((_) {
        animateDetentSettle();
      });
    } else {
      animateDetentSettle();
    }
  }

  void animateDetentSettle() {
    //print("*******************checking detent");
    var angleOfSide = polygon.angleOfSide(itemIndex);
    if (isInDetent()) {
      if (angleOfSide == 0 && currentAngle > pi) {
        angleOfSide = 2 * pi;
      }
      final CurvedAnimation curve = CurvedAnimation(
        parent: settleController,
        curve: Curves.ease,
      );
      settleAnimation = curve.drive(Tween(
        begin: currentAngle,
        end: angleOfSide,
      ));
      //print("*******************animating detent settle");

      settleController.forward(from: 0.0);
    }
  }

  bool isInDetent() {
    var negOffset = _detentNegativeOffsetAngle();
    var posOffset = _detentPositiveOffsetAngle();
    return (itemIndex > 0 &&
            (currentAngle > negOffset) &&
            (currentAngle < posOffset)) ||
        (itemIndex == 0 &&
            ((currentAngle > negOffset) || (currentAngle < posOffset)));
  }

  double _detentPositiveOffsetAngle() {
    var offset = polygon.angleOfSide(itemIndex) +
        polygon.exteriorAngle * detent / 2;
    if (offset > 2 * pi) {
      offset = offset - 2 * pi;
    }
    return offset;
  }

  double _detentNegativeOffsetAngle() {
    var offset = polygon.angleOfSide(itemIndex) -
        polygon.exteriorAngle * detent / 2;
    if (offset < 0) {
      if (offset < 0) {
        offset = 2 * pi - offset.abs();
      }
    }
    return offset;
  }

  double calculateAngularDelta(double linearDelta) {
    //Assume that the linear movement = movement along the circumference. So, 100 pixels of movement on screen translates to 100 "pixels" of circumference movement on dial
    //If we try to translate from linear to
    return linearDelta / polygon.radius;
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

  ///Angle between two lines that connect to both vertices of a side
  double get exteriorAngle => 2 * pi / sides;

  ///Angle between two adjacent sides
  double get interiorAngle => pi - exteriorAngle;

  ///Distance from polygon center to middle of a side
  double get apothem => sideLength / (2 * tan(pi / sides));

  ///Distance from polygon center to vertex
  double get radius => sideLength / (2 * sin(pi / sides));

  ///circumference of circle created by radius
  double get circumference => 2 * pi * radius;

  ///returns the angle of the apothem of a given side measured from 0
  ///assumes the apothem of sideIndex 0 is 0 rad.
  ///Example: the angle for the apothem of of side 3 on a six sided polygon is pi
  double angleOfSide(int sideIndex) {
    return sideIndex * exteriorAngle;
  }
}
