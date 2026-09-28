import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/widgets/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API dates are shown without the time part', () {
    expect(dateOnly('2026-09-01T00:00:00.000000Z'), '2026-09-01');
    expect(dateOnly('2026-09-01'), '2026-09-01');
    expect(dateOnly(null), '');
    expect(displayDate('2026-09-01T00:00:00.000000Z'), '1 Sep 2026');
    expect(displayDate(''), '—');
  });

  test('contract values get thousands separators', () {
    const formatter = ThousandsSeparatorInputFormatter();
    TextEditingValue type(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    expect(type('1250000').text, '1,250,000');
    expect(type('1,250,000.505').text, '1,250,000.50');
    expect(type('abc').text, '');
    expect(parseAmount('1,250,000.50'), 1250000.5);
    expect(amountFieldText(1500000.0), '1,500,000');
    expect(amountFieldText(0), '');
  });

  test('upload names use standard lower-case extensions', () {
    expect(ApiClient.standardUploadName('Scan 01.JPEG'), 'Scan 01.jpg');
    expect(ApiClient.standardUploadName('BOQ.XLSX'), 'BOQ.xlsx');
    expect(ApiClient.standardUploadName('photo'), 'photo.jpg');
  });

  test('profile initials', () {
    const user = UserProfile(name: 'Jane Achieng Doe', email: '', locale: 'en');
    expect(user.initials, 'JA');
    expect(const UserProfile(name: '', email: '', locale: 'en').initials, '?');
  });

  test('BOQ totals parse from the API', () {
    final totals = BoqTotals.fromJson({
      'items': 3,
      'estimated_items': 2,
      'priced_items': 2,
      'estimated_amount': '11000.00',
      'generated_total': 12900,
    });
    expect(totals.difference, 1900);
    expect(totals.hasEstimate, isTrue);
    expect(BoqTotals.fromJson(null).items, 0);
    expect(
      BoqListItem.fromJson({
        'id': 1,
        'totals': {'items': 1, 'generated_total': 5},
      }).totals.generatedTotal,
      5,
    );
  });
}
