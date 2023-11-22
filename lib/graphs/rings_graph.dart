import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:math_graphs/constants/app_colors.dart';
import 'package:math_graphs/constants/app_dimensions.dart';
import 'package:math_graphs/extensions/double.dart';
import 'package:math_graphs/models/ring.dart';

import '../constants/app_functions.dart';

/// A widget that generates and displays a ring graph.
///
/// This widget wraps the [RingGraphPainter] in a [CustomPaint]
/// to make it easier to integrate into source code. It also enables
/// user interaction handling such as updating [frameNo] when the
/// user swipes horizontally.
class RingsGraph extends StatefulWidget {
  RingsGraph({
    this.title = "",
    this.rings = const [],
    this.backgroundColor = AppColors.transparent,
    this.graphLineColor = AppColors.graphGrid,
    this.frameNo = 0,
    this.elementsPerFrame = AppDimensions.maxGraphElements,
    this.colorMap = AppColors.graphColors,
    this.onTap,
    this.onDoubleTap,
  });

  /// The title of the ring graph.
  final String title;

  /// The elements to plot in the graph.
  final List<Ring> rings;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the lines used to display scaled values.
  final Color graphLineColor;

  /// The elements in [rings] to display i.e. [rings] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The colors of each ring in the graph. Note that if
  /// [colorMap].length < [rings].length, i % [colorMap].length will be
  /// used for subsequent rings.
  final List<Color> colorMap;

  /// The maximum number of rings to show on the graph at once.
  final int elementsPerFrame;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<RingsGraph> createState() => _RingsGraphState();
}

class _RingsGraphState extends State<RingsGraph> {
  int _frameNo = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onHorizontalDragUpdate: (details) {
        int sensitivity = AppDimensions.swipeSensitivity;
        if (details.delta.dx > sensitivity) {
          previousFrame();
        } else if (details.delta.dx < -sensitivity) {
          nextFrame();
        }
      },
      child: CustomPaint(
          size: Size.infinite,
          painter: RingsGraphPainter(
              title: widget.title,
              rings: widget.rings,
              backgroundColor: widget.backgroundColor,
              graphLineColor: widget.graphLineColor,
              frameNo: _frameNo,
              elementsPerFrame: widget.elementsPerFrame,
              colorMap: widget.colorMap)),
    );
  }

  nextFrame() {
    if (((_frameNo + 1) * widget.elementsPerFrame) < widget.rings.length) {
      setState(() {
        _frameNo += 1;
      });
    }
  }

  previousFrame() {
    if (_frameNo > 0) {
      setState(() {
        _frameNo -= 1;
      });
    }
  }
}

/// A [CustomPainter] that generates and displays a ring graph.
class RingsGraphPainter extends CustomPainter {
  RingsGraphPainter({
    this.title = "",
    this.rings = const [],
    this.backgroundColor = AppColors.transparent,
    this.graphLineColor = AppColors.graphGrid,
    this.frameNo = 0,
    this.elementsPerFrame = AppDimensions.maxGraphElements,
    this.colorMap = AppColors.graphColors,
  });

  /// The title of the ring graph.
  final String title;

  /// The elements to plot in the graph.
  final List<Ring> rings;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the lines used to display scaled values.
  final Color graphLineColor;

  /// The elements in [rings] to display i.e. [rings] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  int frameNo = 0;

  /// The colors of each ring in the graph. Note that if
  /// [colorMap].length < [rings].length, i % [colorMap].length will be
  /// used for subsequent rings.
  final List<Color> colorMap;

  /// The maximum number of rings to show on the graph at once.
  final int elementsPerFrame;

  final _painter = Paint();
  double _viewHeight = 0.0;
  double _viewWidth = 0.0;
  double _maxRadius = 0.0;
  double _minRadius = 0.0;
  double _leftMargin = 0.0;
  double _radialDifference = 0.0;
  double _midPoint = 0.0;
  double _xCenter = 0.0;
  double _yCenter = 0.0;
  double _fontSize = 0.0;
  double _lineWidth = 0.0;
  double _titleFontSize = 0.0;

  /// Scales relevant parameters of graph to the [size] of the view.
  _setDimensions(Size size) {
    _viewHeight = size.height;
    _viewWidth = size.width;
    _maxRadius = (0.25 * _viewWidth);
    _minRadius = (0.25 * _maxRadius);
    _leftMargin = (0.05 * _viewWidth);
    _radialDifference = _maxRadius - _minRadius;
    _midPoint = (0.5 * _radialDifference);
    _xCenter = _maxRadius + _leftMargin;
    _yCenter = (0.5 * _viewHeight);
    _fontSize = (0.032 * _viewWidth);
    _titleFontSize = 0.06 * _viewWidth;
    _lineWidth = rings.isEmpty ? 0 : _radialDifference / rings.length;
  }

  /// Draws the [title] of the graph on the [canvas].
  _drawTitle(Canvas canvas) {
    final textStyle =
        TextStyle(color: AppColors.graphTitle, fontSize: _titleFontSize);
    final textSpan = TextSpan(text: title, style: textStyle);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: _viewWidth);
    textPainter.paint(canvas,
        Offset(_leftMargin, _yCenter + _maxRadius + (2 * _titleFontSize)));
  }

  /// Draws the outline of the graph on the [canvas] prior to plotting
  /// [rings].
  _drawCircle(Canvas canvas) {
    _painter.style = PaintingStyle.stroke;
    _painter.color = backgroundColor;
    _painter.strokeWidth = 1;
    var rect = Rect.fromLTRB(0, 0, _viewWidth, _viewHeight);
    canvas.drawRect(rect, _painter);
    _painter.color = graphLineColor;
    canvas.drawCircle(Offset(_xCenter, _yCenter), _maxRadius, _painter);
    _painter.color = graphLineColor;
    canvas.drawCircle(Offset(_xCenter, _yCenter), _minRadius, _painter);

    rect =
        Rect.fromCircle(center: Offset(_xCenter, _yCenter), radius: _maxRadius);
    var arc = Path()
      ..addArc(rect.translate(_maxRadius / 4, _maxRadius / 4), 0, 6);
    canvas.drawShadow(arc, Colors.grey.withOpacity(0.2), 10, true);
  }

  /// Plots the [rings] and legends on the [canvas].
  _drawChart(Canvas canvas) {
    var count = 0;
    for (int index = (frameNo * elementsPerFrame);
        index < min(((frameNo + 1) * elementsPerFrame), rings.length);
        index++) {
      Ring ring = rings[index];
      final text =
          '${ring.title} (${AppFunctions.prettyPercentage((ring.ratio.toDecimal * Decimal.fromInt(100)))})';
      final color = colorMap[index % colorMap.length];
      final textStyle = TextStyle(
          color: color, fontSize: _fontSize, fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
      _painter.style = PaintingStyle.stroke;
      _painter.strokeWidth = _lineWidth * 0.85;
      var rect = Rect.fromCircle(
        center: Offset(_xCenter, _yCenter),
        radius: _minRadius + (0.5 + count) * _lineWidth,
      );
      _painter.color = color.withOpacity(0.3);
      canvas.drawArc(rect, 0, AppFunctions.radians(360.0), false, _painter);
      _painter.color = color;
      canvas.drawArc(
          rect, 0, AppFunctions.radians(ring.ratio * 360), false, _painter);
      _painter.style = PaintingStyle.fill;
      textPainter.paint(
          canvas,
          Offset(_leftMargin + (2 * _maxRadius) + (0.5 * _midPoint / 1.5),
              ((++count * 1.5) + 2) * _fontSize));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide > 0) {
      _setDimensions(size);
      _drawCircle(canvas);
      _drawTitle(canvas);
      if (!rings.isEmpty) {
        _drawChart(canvas);
      }
    }
  }
}
