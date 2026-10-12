/// Null-safe, type-tolerant readers for decoded API JSON.
///
/// The API may return `null`, omit a field, or send numbers as strings
/// (`"12"`, `"1250.50"`). These helpers never throw: they coerce what they
/// can and fall back to an empty/zero value (or `null` for the `OrNull`
/// variants) otherwise.
library;

/// An integer from a number, numeric string or bool; [fallback] otherwise.
int jsonInt(dynamic value, [int fallback = 0]) =>
    jsonIntOrNull(value) ?? fallback;

int? jsonIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.toInt() : null;
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    final text = value.trim();
    return int.tryParse(text) ?? double.tryParse(text)?.toInt();
  }
  return null;
}

/// A double from a number or numeric string (thousands separators allowed).
double jsonDouble(dynamic value, [double fallback = 0.0]) =>
    jsonDoubleOrNull(value) ?? fallback;

double? jsonDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }
  return null;
}

/// A string; numbers/bools are converted with `toString()`. Maps and lists
/// are not meaningful as text and give [fallback].
String jsonString(dynamic value, [String fallback = '']) =>
    jsonStringOrNull(value) ?? fallback;

String? jsonStringOrNull(dynamic value) {
  if (value == null || value is Map || value is List) return null;
  return value is String ? value : '$value';
}

/// A bool from `true`/`false`, `1`/`0` or `"true"`/`"1"`/`"yes"`.
bool jsonBool(dynamic value, [bool fallback = false]) =>
    jsonBoolOrNull(value) ?? fallback;

bool? jsonBoolOrNull(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true' || '1' || 'yes' || 'on':
        return true;
      case 'false' || '0' || 'no' || 'off' || '':
        return false;
    }
  }
  return null;
}

/// A JSON object; anything else gives an empty map.
Map<String, dynamic> jsonMap(dynamic value) =>
    jsonMapOrNull(value) ?? <String, dynamic>{};

Map<String, dynamic>? jsonMapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry('$key', v));
  }
  return null;
}

/// A JSON array; anything else gives an empty list.
List<dynamic> jsonList(dynamic value) =>
    value is List ? value : const <dynamic>[];

List<dynamic>? jsonListOrNull(dynamic value) => value is List ? value : null;

/// The JSON objects of an array, skipping non-object entries.
List<Map<String, dynamic>> jsonMaps(dynamic value) => jsonList(
  value,
).map(jsonMapOrNull).whereType<Map<String, dynamic>>().toList();
