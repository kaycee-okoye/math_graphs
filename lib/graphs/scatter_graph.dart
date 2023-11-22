import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:math_graphs/constants/app_colors.dart';
import 'package:math_graphs/constants/app_dimensions.dart';
import 'package:math_graphs/extensions/double.dart';
import 'package:math_graphs/models/scatter_point.dart';

class ScatterGraph extends StatefulWidget {
  ScatterGraph(
      {this.title = "",
      this.unit = "",
      this.scatterPoints = const [],
      this.legends = const [],
      this.backgroundColor = AppColors.transparent,
      this.graphLineColor = AppColors.graphGrid,
      this.pointSize = 10.0,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.showPercentiles = const [0.01, 0.25, 0.5, 0.75, 1.0],
      this.colorMap = AppColors.graphColors,
      this.onTap,
      this.onDoubleTap,
      required this.connectPoints});

  /// The title of the scatter graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;

  /// The elements to plot in the graph.
  final List<ScatterPoint> scatterPoints;

  /// The titles of each series to be displayed in the legends on the graph
  final List<String> legends;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the horizontal lines used to display scaled
  /// [showPercentiles] values.
  final Color graphLineColor;

  /// The elements in [scatterPoints] to display i.e. [scatterPoints] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The percentages of the maximum y-value at which to draw horizontal lines
  /// on the graph.
  final List<double> showPercentiles;

  /// The colors of each series in the graph. Note that if
  /// [colorMap].length < [scatterPoint].values.length, i % [colorMap].length will be
  /// used for subsequent points.
  final List<Color> colorMap;

  /// The maximum number of [scatterPoints] to show on the graph at once.
  final int elementsPerFrame;

  /// The size of the marker's displayed on the graph
  final double pointSize;

  /// Whether to connect scatterPoints in the same series with lines.
  final bool connectPoints;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<ScatterGraph> createState() => _ScatterGraphState();
}

class _ScatterGraphState extends State<ScatterGraph> {
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
          painter: ScatterGraphPainter(
              title: widget.title,
              unit: widget.unit,
              scatterPoints: widget.scatterPoints,
              legends: widget.legends,
              backgroundColor: widget.backgroundColor,
              graphLineColor: widget.graphLineColor,
              pointSize: widget.pointSize,
              frameNo: widget.frameNo,
              elementsPerFrame: widget.elementsPerFrame,
              showPercentiles: widget.showPercentiles,
              colorMap: widget.colorMap,
              connectPoints: widget.connectPoints)),
    );
  }

  /// Updates the graph to display the next frame.
  nextFrame() {
    if (((_frameNo + 1) * widget.elementsPerFrame) <
        widget.scatterPoints.length) {
      setState(() {
        _frameNo += 1;
      });
    }
  }

  /// Updates the graph to display the previous frame.
  previousFrame() {
    if (_frameNo > 0) {
      setState(() {
        _frameNo -= 1;
      });
    }
  }
}

/// A [CustomPainter] that generates and displays a scatter graph.
class ScatterGraphPainter extends CustomPainter {
  ScatterGraphPainter(
      {this.title = "",
      this.unit = "",
      this.scatterPoints = const [],
      this.legends = const [],
      this.backgroundColor = AppColors.transparent,
      this.graphLineColor = AppColors.graphGrid,
      this.pointSize = 10.0,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.showPercentiles = const [0.01, 0.25, 0.5, 0.75, 1.0],
      this.colorMap = AppColors.graphColors,
      this.connectPoints = true});

  /// The title of the scatter graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;

  /// The elements to plot in the graph.
  final List<ScatterPoint> scatterPoints;

  /// The titles of each series to be displayed in the legends on the graph
  final List<String> legends;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the horizontal lines used to display scaled
  /// [showPercentiles] values.
  final Color graphLineColor;

  /// The elements in [scatterPoints] to display i.e. [scatterPoints] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  int frameNo = 0;

  /// The percentages of the maximum y-value at which to draw horizontal lines
  /// on the graph.
  final List<double> showPercentiles;

  /// The colors of each series in the graph. Note that if
  /// [colorMap].length < [scatterPoint].values.length, i % [colorMap].length will be
  /// used for subsequent points.
  final List<Color> colorMap;

  /// The maximum number of [scatterPoints] to show on the graph at once.
  final int elementsPerFrame;

  /// The size of the marker's displayed on the graph
  final double pointSize;

  /// Whether to connect scatterPoints in the same series with lines.
  final bool connectPoints;

  final _painter = Paint();
  double _viewHeight = 0.0;
  double _viewWidth = 0.0;
  double _leftMargin = 0.0;
  double _rightMargin = 0.0;
  double _bottomMargin = 0.0;
  double _fontSize = 0.0;
  double _titleFont = 0.0;

  /// The maximum allowed height of a [scatterPoints] on the canvas.
  double _maxScaledY = 0.0;

  /// The maximum amount in [scatterPoints].
  Decimal _maxRawY = Decimal.zero;

  /// The ratio used to scale height of all the [scatterPoints]
  Decimal _scale = Decimal.zero;

  /// Scales relevant parameters of graph to the [size] of the view.
  _setDimensions(Size size) {
    _viewHeight = size.height;
    _viewWidth = size.width;
    _leftMargin = _viewWidth / 7;
    _rightMargin = _viewWidth / 4;
    _bottomMargin = (0.75 * _viewHeight);
    _fontSize = (0.032 * _viewWidth);
    _titleFont = 0.06 * _viewWidth;
    _maxScaledY = (_viewHeight - (0.8 * _bottomMargin));
  }

  /// Draws the [title] of the graph on the [canvas].
  _drawTitle(Canvas canvas) {
    final textStyle =
        TextStyle(color: AppColors.graphTitle, fontSize: _titleFont);
    final textSpan = TextSpan(text: title, style: textStyle);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: _viewWidth);
    textPainter.paint(
        canvas, Offset(_leftMargin, _bottomMargin + (_titleFont)));
  }

  /// Draws the outline of the graph on the [canvas] prior to plotting [scatterPoints].
  /// Also draws [showPercentiles] and [legends].
  _drawGraph(Canvas canvas) {
    _painter.style = PaintingStyle.fill;
    _painter.color = backgroundColor;
    var rect = Rect.fromLTWH(0, 0, _viewWidth, _viewHeight);
    canvas.drawRect(rect, _painter);

    _painter.style = PaintingStyle.stroke;
    _painter.strokeWidth = 2;
    var percentiles = [0.01, 0.25, 0.5, 0.75, 1.0];
    for (double percentile in percentiles) {
      _painter.color = graphLineColor;
      canvas.drawLine(
          Offset(_leftMargin, _bottomMargin - (percentile * _maxScaledY)),
          Offset(_viewWidth - _rightMargin,
              _bottomMargin - (percentile * _maxScaledY)),
          _painter);

      if (_maxRawY != Decimal.zero) {
        final text = unit +
            " " +
            (percentile.toDecimal * _maxRawY).toDouble().prettifyMoney;
        final color = graphLineColor.withOpacity(1.0);
        final textStyle = TextStyle(color: color, fontSize: 0.9 * _fontSize);
        final textSpan = TextSpan(text: text, style: textStyle);
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
        _painter.color = color;
        textPainter.paint(
            canvas, Offset(2, _bottomMargin - (percentile * _maxScaledY)));
      }
    }

    var count = 2;
    for (String legend in legends) {
      final text = legend;
      final color = colorMap[legends.indexOf(legend) % colorMap.length];
      final textStyle = TextStyle(
          color: color, fontSize: _fontSize, fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
      _painter.color = color;
      textPainter.paint(
          canvas, Offset(_viewWidth - _rightMargin, ++count * _fontSize * 1.5));
    }
  }

  /// Plots the [scatterPoints] and legends on the [canvas].
  _drawChart(Canvas canvas) {
    var count = 1;
    double multiplier = ((_viewWidth - _leftMargin - _rightMargin) /
        ((scatterPoints.length * 2) + 1));

    var lastX = 0.0;
    final lastYs = [];
    for (int index = (frameNo * elementsPerFrame);
        index < min(((frameNo + 1) * elementsPerFrame), scatterPoints.length);
        index++) {
      final scatterPoint = scatterPoints[index];
      final left = _leftMargin + (2 * ((++count - 2) * multiplier));
      final currentX = left + ((multiplier - pointSize) / 2);
      final currentYs = [];
      for (int i = 0; i < scatterPoint.values.length; i++) {
        final height = (scatterPoint.values[i].toDecimal * _scale).toDouble();
        final currentY = _bottomMargin - (height);
        currentYs.add(currentY);
        final color = colorMap[i % colorMap.length];
        _painter.style = PaintingStyle.fill;
        _painter.color = color;
        var rect = Rect.fromLTWH(currentX,
            _bottomMargin - (height + pointSize / 2), pointSize, pointSize);
        canvas.drawRect(rect, _painter);
        canvas.drawShadow(Path()..addRect(rect.translate(multiplier / 3, 0)),
            Colors.grey.withOpacity(0.9), _viewHeight / 30, true);

        if (connectPoints) {
          if (i < lastYs.length) {
            _painter.style = PaintingStyle.stroke;
            _painter.strokeWidth = pointSize / 3;
            _painter.color = color.withOpacity(0.3);
            canvas.drawLine(
                Offset(lastX, lastYs[i]), Offset(currentX, currentY), _painter);
          }
        }
      }
      lastX = currentX + (pointSize / 2);
      lastYs.clear();
      lastYs.addAll(currentYs);

      final text = scatterPoint.title;
      final color = graphLineColor.withOpacity(1.0);
      final textStyle = TextStyle(
          color: color, fontSize: _fontSize, fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
      _painter.color = color;
      textPainter.paint(canvas,
          Offset(left + (multiplier * 0.3), _bottomMargin + (_fontSize * 1.5)));
    }
  }

  /// Calculates the ratio used to scale height of all the [scatterPoints]
  ///
  /// The scaling ratio is calculated as [_maxRawY] / [_maxScaledY].
  _calculateScale() {
    if (!scatterPoints.isEmpty) {
      // find the maximum raw value
      _maxRawY = Decimal.zero;
      for (ScatterPoint x in scatterPoints) {
        for (double other in x.values) {
          if (other.toDecimal > _maxRawY) {
            _maxRawY = other.toDecimal;
          }
        }
      }

      if (_maxScaledY != Decimal.zero) {
        _scale = (_maxRawY / _maxScaledY.toDecimal)
            .toDecimal(scaleOnInfinitePrecision: 10);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _calculateScale();
    if (size.shortestSide > 0) {
      _setDimensions(size);
      _drawGraph(canvas);
      _drawTitle(canvas);
      if (!scatterPoints.isEmpty) {
        _drawChart(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
