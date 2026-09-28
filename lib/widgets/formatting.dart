import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Returns just the `YYYY-MM-DD` part of an API date/time string
/// (`2026-09-01T00:00:00.000000Z` → `2026-09-01`). Other values are returned
/// unchanged; empty input stays empty.
String dateOnly(String? value) {
  final raw = (value ?? '').trim();
  final match = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw);
  return match?.group(0) ?? raw;
}

/// Displays an API date as e.g. `1 Sep 2026`; falls back to the raw value.
String displayDate(String? value, {String pattern = 'd MMM yyyy'}) {
  final raw = dateOnly(value);
  if (raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : DateFormat(pattern).format(parsed);
}

/// Parses an amount typed with thousands separators (`1,250,000.50`).
double? parseAmount(String text) =>
    double.tryParse(text.replaceAll(',', '').trim());

/// Formats a number for an amount text field (`1250000.0` → `1,250,000`).
String amountFieldText(num? value) {
  if (value == null || value == 0) return '';
  return NumberFormat(
    value % 1 == 0 ? '#,##0' : '#,##0.##',
    'en_US',
  ).format(value);
}

/// Inserts thousands separators while an amount is typed.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return newValue.copyWith(text: '');

    final parts = cleaned.split('.');
    // Reject a second decimal point.
    if (parts.length > 2) return oldValue;

    final whole = parts.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (whole.length > 15) return oldValue;
    final grouped = whole.isEmpty
        ? '0'
        : NumberFormat('#,##0', 'en_US').format(int.parse(whole));
    final decimals = parts.length == 2
        ? '.${parts[1].substring(0, parts[1].length.clamp(0, 2))}'
        : '';
    final text = '$grouped$decimals';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
