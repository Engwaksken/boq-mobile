import 'package:boq_mobile/json_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numbers tolerate strings, nulls and garbage', () {
    expect(jsonInt('12'), 12);
    expect(jsonInt('12.7'), 12);
    expect(jsonInt(3.9), 3);
    expect(jsonInt(null), 0);
    expect(jsonInt('abc', 5), 5);
    expect(jsonIntOrNull('abc'), isNull);
    expect(jsonDouble('1,250.50'), 1250.5);
    expect(jsonDouble(7), 7.0);
    expect(jsonDoubleOrNull(null), isNull);
  });

  test('strings, bools and collections never throw', () {
    expect(jsonString(42), '42');
    expect(jsonString(null, 'x'), 'x');
    expect(jsonStringOrNull({'a': 1}), isNull);
    expect(jsonBool('1'), isTrue);
    expect(jsonBool(0), isFalse);
    expect(jsonBool('maybe', true), isTrue);
    expect(jsonMap('nope'), isEmpty);
    expect(jsonMap({1: 'a'}), {'1': 'a'});
    expect(jsonList(null), isEmpty);
    expect(jsonMaps([{'a': 1}, 'x', null]), [{'a': 1}]);
  });
}
