import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:math_graphs/extensions/double.dart';

/// Common functions used in the package
class AppFunctions {
  /// Displays percentage with 2 decimal places and a percent sign
  static String prettyPercentage(Object value) {
    String output = '%';
    Decimal newValue = Decimal.zero;
    if (value is Decimal) {
      output = value.toStringAsFixed(2) + output;
      newValue = Decimal.parse(value.toStringAsFixed(2));
    } else if (value is double) {
      output = value.toStringAsFixed(2) + output;
      newValue = Decimal.parse(value.toStringAsFixed(2));
    }
    if (newValue == Decimal.zero) {
      return "~ 0%";
    }
    return output;
  }

  /// Converts [degrees] from degrees to radians
  static double radians(Object degrees) {
    Decimal degree = Decimal.zero;
    if (degrees is double) {
      degree = degrees.toDecimal;
    } else if (degrees is Decimal) {
      degree = degrees;
    }
    Decimal radians = ((degree * pi.toDecimal) / Decimal.fromInt(180))
        .toDecimal(scaleOnInfinitePrecision: 10);
    return radians.toDouble();
  }
}
