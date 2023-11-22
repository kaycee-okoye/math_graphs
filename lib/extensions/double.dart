import 'package:decimal/decimal.dart';

/// Converts a dart [double] to a [Decimal].
///
/// This improves the accuracy of the numbers
extension DecimalParsing on double {
  Decimal get toDecimal => Decimal.parse(this.toString());
}

/// Shortens numbers using metric prefix system
extension DoubleParsing on double {
  String get prettifyMoney {
    final suffixes = ['K', 'M', 'B', 'T', 'Q'];
    final isNegative = sign < 0.0;
    final stringRep = this.abs().toStringAsFixed(2);
    final stringLength = stringRep.length;
    final decimalLocation = stringRep.indexOf('.');
    final nBeforeDecimal =
        decimalLocation == -1 ? stringLength : decimalLocation;
    if (nBeforeDecimal < 4) {
      return isNegative ? "-$stringRep" : stringRep;
    } else {
      final order = ((nBeforeDecimal - 1) / 3).floor();
      final mod = (nBeforeDecimal - 1) % 3;
      late String value;
      late String output;
      if (mod == 0) {
        value = stringRep.substring(0, 1) + '.' + stringRep.substring(1, 3);
      } else if (mod == 1) {
        value = stringRep.substring(0, 2) + '.' + stringRep.substring(2, 3);
      } else {
        value = stringRep.substring(0, 3);
      }

      if (order <= suffixes.length) {
        output = '$value ${suffixes[order - 1]}';
      } else {
        output = '$value E${nBeforeDecimal - 1}';
      }
      return isNegative ? "-$output" : output;
    }
  }
}
