import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:math_graphs/constants/app_colors.dart';
import 'package:math_graphs/extensions/double.dart';
import 'package:math_graphs/models/bar.dart';
import '../constants/app_dimensions.dart';

/// A widget that generates and displays a bar graph.
///
/// This widget wraps the [BarGraphPainter] in a [CustomPaint]
/// to make it easier to integrate into source code. It also enables
/// user interaction handling such as updating [frameNo] when the
/// user swipes horizontally.
class BarGraph extends StatefulWidget {
  const BarGraph(
      {super.key,
      this.title = "",
      this.unit = "",
      this.bars = const [],
      this.backgroundColor = AppColors.transparent,
      this.graphLineColor = AppColors.graphGrid,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.showPercentiles = const [0.01, 0.25, 0.5, 0.75, 1.0],
      this.colorMap = AppColors.graphColors,
      this.onTap,
      this.onDoubleTap});

  /// The title of the bar graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the horizontal lines used to display scaled.
  /// [showPercentiles] values
  final Color graphLineColor;

  /// The elements in [bars] to display i.e. [bars] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The elements to plot in the graph.
  final List<Bar> bars;

  /// The percentages of the maximum y-value at which to draw horizontal lines.
  /// on the graph
  final List<double> showPercentiles;

  /// The colors of each bar in the graph. Note that if
  /// [colorMap].length < [bars].length, i % [colorMap].length will be
  /// used for subsequent bars.
  final List<Color> colorMap;

  /// The maximum number of bars to show on the graph at once.
  final int elementsPerFrame;

  /// Method called when the widget is tapped.
  final VoidCallback? onTap;

  /// Method called when the widget is double-tapped.
  final VoidCallback? onDoubleTap;

  @override
  State<BarGraph> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
  int _frameNo = 0;

  @override
  void initState() {
    _frameNo = widget.frameNo;
    super.initState();
  }

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
          painter: BarGraphPainter(
              title: widget.title,
              unit: widget.unit,
              bars: widget.bars,
              backgroundColor: widget.backgroundColor,
              graphLineColor: widget.graphLineColor,
              frameNo: widget.frameNo,
              elementsPerFrame: widget.elementsPerFrame,
              showPercentiles: widget.showPercentiles,
              colorMap: widget.colorMap)),
    );
  }

  /// Updates the graph to display the next frame.
  nextFrame() {
    if (((_frameNo + 1) * widget.elementsPerFrame) < widget.bars.length) {
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

/// A [CustomPainter] that generates and displays a bar graph.
class BarGraphPainter extends CustomPainter {
  BarGraphPainter(
      {this.title = "",
      this.unit = "",
      this.bars = const [],
      this.backgroundColor = AppColors.transparent,
      this.graphLineColor = AppColors.graphGrid,
      this.frameNo = 0,
      this.elementsPerFrame = AppDimensions.maxGraphElements,
      this.showPercentiles = const [0.01, 0.25, 0.5, 0.75, 1.0],
      this.colorMap = AppColors.graphColors});

  /// The title of the bar graph.
  final String title;

  /// The unit displayed for the scaled [showPercentiles] values.
  final String unit;

  /// The background color of the graph.
  final Color backgroundColor;

  /// The color of the horizontal lines used to display scaled
  /// [showPercentiles] values.
  final Color graphLineColor;

  /// The elements in [bars] to display i.e. [bars] where
  /// index >= [frameNo] x [elementsPerFrame] &&
  /// index < ([frameNo]+1) x [elementsPerFrame].
  final int frameNo;

  /// The elements to plot in the graph.
  final List<Bar> bars;

  /// The percentages of the maximum y-value at which to draw horizontal lines
  /// on the graph.
  final List<double> showPercentiles;

  /// The colors of each bar in the graph. Note that if
  /// [colorMap].length < [bars].length, i % [colorMap].length will be
  /// used for subsequent bars.
  final List<Color> colorMap;

  /// The maximum number of bars to show on the graph at once.
  final int elementsPerFrame;

  final _painter = Paint();
  double _viewHeight = 0.0;
  double _viewWidth = 0.0;
  double _leftMargin = 0.0;
  double _rightMargin = 0.0;
  double _bottomMargin = 0.0;
  double _fontSize = 0.0;
  double _titleFontSize = 0.0;

  /// The maximum allowed height of a bar on the canvas.
  double _maxScaledY = 0.0;

  /// The maximum bar.amount in [bars].
  Decimal _maxRawY = Decimal.zero;

  /// The ratio used to scale height of all the [bars]
  Decimal _scale = Decimal.zero;

  /// Scales relevant parameters of graph to the [size] of the view.
  _setDimensions(Size size) {
    _viewHeight = size.height;
    _viewWidth = size.width;
    _leftMargin = _viewWidth / 7;
    _rightMargin = _viewWidth / 4;
    _bottomMargin = (0.75 * _viewHeight);
    _fontSize = (0.032 * _viewWidth);
    _titleFontSize = 0.06 * _viewWidth;
    _maxScaledY = (_viewHeight - (0.8 * _bottomMargin));
  }

  /// Draws the [title] of the graph on the [canvas].
  _drawTitle(Canvas canvas) {
    final textStyle =
        TextStyle(color: AppColors.graphTitle, fontSize: _titleFontSize);
    final textSpan = TextSpan(text: title, style: textStyle);
    final textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: _viewWidth);
    textPainter.paint(
        canvas, Offset(_leftMargin, _bottomMargin + (_titleFontSize)));
  }

  /// Draws the outline of the graph on the [canvas] prior to plotting [bars].
  /// Also draws [showPercentiles].
  _drawGraph(Canvas canvas) {
    _painter.style = PaintingStyle.fill;
    _painter.color = backgroundColor;
    var rect = Rect.fromLTWH(0, 0, _viewWidth, _viewHeight);
    canvas.drawRect(rect, _painter);

    _painter.style = PaintingStyle.stroke;
    _painter.strokeWidth = 2;
    for (double percentile in showPercentiles) {
      _painter.color = graphLineColor;
      canvas.drawLine(
          Offset(_leftMargin, _bottomMargin - (percentile * _maxScaledY)),
          Offset(_viewWidth - _rightMargin,
              _bottomMargin - (percentile * _maxScaledY)),
          _painter);

      if (_maxRawY != Decimal.zero) {
        final amount = percentile < 0.1
            ? "0.00"
            : (percentile.toDecimal * _maxRawY).toDouble().prettifyMoney;
        final text = unit + " " + amount;
        final color = graphLineColor.withOpacity(1.0);
        final textStyle = TextStyle(color: color, fontSize: _fontSize * 0.9);
        final textSpan = TextSpan(text: text, style: textStyle);
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
        _painter.color = color;
        textPainter.paint(
            canvas, Offset(0, _bottomMargin - (percentile * _maxScaledY)));
      }
    }
  }

  /// Plots the [bars] and legends on the [canvas].
  _drawChart(Canvas canvas) {
    _calculateScale();
    var count = 2;
    _painter.style = PaintingStyle.fill;
    double multiplier =
        ((_viewWidth - _leftMargin - _rightMargin) / ((bars.length * 2) + 1));

    for (int index = (frameNo * elementsPerFrame);
        index < min(((frameNo + 1) * elementsPerFrame), bars.length);
        index++) {
      final bar = bars[index];
      final height = (bar.value.toDecimal * _scale).toDouble();
      final text = bar.title;
      final color = colorMap[index % colorMap.length];
      final textStyle = TextStyle(
          color: color, fontSize: _fontSize, fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: _viewWidth / 2);
      _painter.color = color;
      var rect = Rect.fromLTWH(_leftMargin + (2 * ((count - 2) * multiplier)),
          _bottomMargin - height, multiplier, height);
      canvas.drawRect(rect, _painter);
      textPainter.paint(
          canvas, Offset(_viewWidth - _rightMargin, ++count * _fontSize * 1.5));
      canvas.drawShadow(Path()..addRect(rect.translate(multiplier / 3, 0)),
          Colors.grey.withOpacity(0.9), _viewHeight / 30, true);
    }
  }

  /// Calculates the ratio used to scale height of all the [bars]
  ///
  /// The scaling ratio of a bar in the graph is calculated as
  /// [_maxRawY] / [_maxScaledY].
  _calculateScale() {
    if (!bars.isEmpty) {
      // find the maximum raw value of the bars
      _maxRawY = Decimal.zero;
      for (Bar x in bars) {
        Decimal other = x.value.toDecimal;
        if (other > _maxRawY) {
          _maxRawY = other;
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
      if (!bars.isEmpty) {
        _drawChart(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
