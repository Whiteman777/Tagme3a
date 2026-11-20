import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('en_US');

String formatNumber(num value) => _decimal.format(value);

String formatEgp(num value) => '${_decimal.format(value)}\u00A0ج.م';

String formatCompactEgp(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)} مليون ج.م';
  }
  if (value >= 1000) {
    final thousands = value / 1000;
    final text = thousands == thousands.roundToDouble()
        ? thousands.round().toString()
        : thousands.toStringAsFixed(1);
    return '$text ألف ج.م';
  }
  return formatEgp(value);
}
