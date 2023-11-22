import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:math_graphs/constants/app_colors.dart';
import 'package:math_graphs/constants/app_dimensions.dart';
import 'package:math_graphs/constants/app_functions.dart';
import 'package:math_graphs/extensions/double.dart';
import 'package:math_graphs/models/pie_slice.dart';

/// A widget that generates and displays a pie graph.
///
/// This widget wraps the [PieGraphPainter] in a [CustomPaint]
/// to make it easier to integrate into source code. It also enables
/// user interaction handling such as updating [frameNo] when the
/// user swipes horizontally.
class PieGraph extends StatefulWidget {
  PieGraph(
      {this.title = "",
      this.unit = "",
      this.pieSlices = const [],
      this.backgroundColor = AppColors.transparent,
      this.pieType = PieType.floating,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.colorMap = AppColors.graphColors,
      this.onTap,
      this.onDoubleTap});

  /// The title of the pie graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;
  final List<PieSlice> pieSlices;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The description of whether to draw a filled circle or just
  /// the perimeter of the pie graph
  final PieType pieType;

  /// The elements in [pieSlices] to display i.e. [pieSlices] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The colors of each pieSlice in the graph. Note that if
  /// [colorMap].length < [pieSlices].length, i % [colorMap].length will be
  /// used for subsequent pieSlices.
  final List<Color> colorMap;

  /// The maximum number of pieSlices to show on the graph at once.
  final int elementsPerFrame;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<PieGraph> createState() => _PieGraphState();
}

class _PieGraphState extends State<PieGraph> {
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
            painter: PieGraphPainter(
                title: widget.title,
                unit: widget.unit,
                pieSlices: widget.pieSlices,
                backgroundColor: widget.backgroundColor,
                pieType: widget.pieType,
                frameNo: _frameNo,
                elementsPerFrame: widget.elementsPerFrame,
                colorMap: widget.colorMap)));
  }

  nextFrame() {
    if (((_frameNo + 1) * widget.elementsPerFrame) < widget.pieSlices.length) {
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

/// A [CustomPainter] that generates and displays a pie graph.
class PieGraphPainter extends CustomPainter {
  PieGraphPainter(
      {this.title = "",
      this.unit = "",
      this.pieSlices = const [],
      this.backgroundColor = AppColors.transparent,
      this.pieType = PieType.floating,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.colorMap = AppColors.graphColors});

  /// The title of the pie graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;

  /// The elements to plot in the graph.
  final List<PieSlice> pieSlices;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The description of whether to draw a filled circle or just
  /// the perimeter of the pie graph
  final PieType pieType;

  /// The elements in [pieSlices] to display i.e. [pieSlices] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The colors of each pieSlice in the graph. Note that if
  /// [colorMap].length < [pieSlices].length, i % [colorMap].length will be
  /// used for subsequent pieSlices.
  final List<Color> colorMap;

  /// The maximum number of pieSlices to show on the graph at once.
  final int elementsPerFrame;

  final _painter = Paint();
  double _viewHeight = 0.0;
  double _viewWidth = 0.0;
  double _pieRadius = 0.0;
  double _leftMargin = 0.0;
  double _midPoint = 0.0;
  double _xCenter = 0.0;
  double _yCenter = 0.0;
  double _fontSize = 0.0;

  double _titleFontSize = 0.0;
  double _totalSpacing = 30.0;
  double _spacing = 0.0;
  double _pieStroke = 0.0;

  /// The sum of all [PieSlice] values in [pieSlices]
  Decimal _total = Decimal.zero;

  /// Scales relevant parameters of graph to the [size] of the view.
  _setDimensions(Size size) {
    _viewHeight = size.height;
    _viewWidth = size.width;
    _pieRadius = (0.2 * _viewWidth);
    _leftMargin = (0.05 * _viewWidth);
    _midPoint = (0.25 * _leftMargin);
    _xCenter = _pieRadius + _leftMargin;
    _yCenter = (0.5 * _viewHeight);
    _fontSize = (0.032 * _viewWidth);
    _titleFontSize = 0.07 * _viewWidth;
    _pieStroke = _viewWidth / 10;
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
        Offset(_leftMargin, _yCenter + _pieRadius + (_titleFontSize / 3)));
  }

  /// Draws the outline of the graph on the [canvas] prior to plotting
  /// [pieSlices].
  _drawPie(Canvas canvas) {
    _painter.style = PaintingStyle.fill;
    _painter.color = backgroundColor;
    var rect = Rect.fromLTWH(0, 0, _viewWidth, _viewHeight);
    canvas.drawRect(rect, _painter);

    if (pieType == PieType.floating) {
      _painter.style = PaintingStyle.stroke;
      _painter.strokeWidth = 20;
    } else if (pieType == PieType.connected) {
      _painter.style = PaintingStyle.fill;
    }
    _painter.color = backgroundColor;
    canvas.drawCircle(Offset(_xCenter, _yCenter), _pieRadius, _painter);
    _painter.style = PaintingStyle.fill;
  }

  /// Plots the [pieSlices] and legends on the [canvas].
  _drawChart(Canvas canvas) {
    _scaleValues();
    var angle = Decimal.zero;
    var count = 2;
    var diagonal = _pieRadius / 3;
    var textX = pieType == PieType.floating
        ? _leftMargin + (2 * _pieRadius) + (0.5 * _midPoint / 1.5) + _pieStroke
        : _leftMargin + (2 * _pieRadius) + (0.5 * _midPoint / 1.5);
    var rect =
        Rect.fromCircle(center: Offset(_xCenter, _yCenter), radius: _pieRadius);
    var arc = Path()..addArc(rect.translate(diagonal, diagonal), 0, 6);
    canvas.drawShadow(arc, Colors.grey.withOpacity(0.75), 10, true);

    for (int index = (frameNo * elementsPerFrame);
        index < min(((frameNo + 1) * elementsPerFrame), pieSlices.length);
        index++) {
      final pieSlice = pieSlices[index];
      final color = colorMap[pieSlices.indexOf(pieSlice) % colorMap.length];
      _painter.color = color;
      _painter.style = PaintingStyle.fill;

      final text =
          '${pieSlice.title} (${AppFunctions.prettyPercentage((pieSlice.relativeValue.toDecimal / Decimal.fromInt(360)).toDecimal(scaleOnInfinitePrecision: 2) * Decimal.fromInt(100))})';
      final textStyle = TextStyle(
          color: color, fontSize: _fontSize, fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);

      if (pieType == PieType.floating) {
        _painter.style = PaintingStyle.stroke;
        _painter.strokeWidth = 20;
      } else if (pieType == PieType.connected) {
        _painter.style = PaintingStyle.fill;
      }

      var startAngle = AppFunctions.radians(angle);
      var sweepAngle = AppFunctions.radians(
          pieSlice.relativeValue.toDecimal - _spacing.toDecimal);
      canvas.drawArc(
          rect, startAngle, sweepAngle, pieType != PieType.floating, _painter);
      angle += pieSlice.relativeValue.toDecimal;
      if ((index >= (frameNo * elementsPerFrame)) &&
          (index < ((frameNo + 1) * elementsPerFrame))) {
        textPainter.paint(canvas, Offset(textX, ++count * _fontSize * 1.5));
      }
    }

    Color color = AppColors.graphTitle;
    final text = 'Total: $unit $_total';
    final textStyle = TextStyle(color: color, fontSize: _fontSize);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
    count += 5;
    textPainter.paint(canvas, Offset(textX, ++count * _fontSize));
  }

  /// Calculates the ratio used to scale sweep angle of all the [pieSlices]
  ///
  /// For each element [pieSlices], this is calculated as its value / [_total]
  _scaleValues() {
    if (!pieSlices.isEmpty) {
      if (pieSlices.length == 1) {
        _totalSpacing = 0;
      }

      _total = Decimal.zero;
      _spacing = _totalSpacing / pieSlices.length.toDouble();
      for (PieSlice pieSlice in pieSlices) {
        _total += pieSlice.value.toDecimal;
      }

      for (int index = 0; index < pieSlices.length; index++) {
        PieSlice pieSlice = pieSlices[index];
        Decimal ratio = Decimal.zero;
        if (_total != Decimal.zero) {
          Decimal other = pieSlice.value.toDecimal;
          ratio = (other / _total).toDecimal(scaleOnInfinitePrecision: 10) *
              Decimal.fromInt(360);
        }
        pieSlice.relativeValue = ratio.toDouble();
        pieSlices[index] = pieSlice;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide > 0) {
      _setDimensions(size);
      _drawPie(canvas);
      _drawTitle(canvas);
      if (!pieSlices.isEmpty) {
        _drawChart(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Enum describing whether to draw a filled circle or just
/// the perimeter of the pie graph
enum PieType { floating, connected }
