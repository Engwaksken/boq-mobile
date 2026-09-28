import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:boq_mobile/upload_compression.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('large photos are resized and re-encoded as JPEG', () async {
    final random = Random(1);
    final photo = img.Image(width: 3000, height: 1000);
    for (final pixel in photo) {
      pixel
        ..r = random.nextInt(256)
        ..g = random.nextInt(256)
        ..b = random.nextInt(256);
    }
    final png = img.encodePng(photo);

    final prepared = await prepareUpload(name: 'Scan 1.PNG', bytes: png);

    expect(prepared.name, 'Scan 1.jpg');
    expect(prepared.compressed, isTrue);
    final decoded = img.decodeJpg(prepared.bytes!)!;
    expect(decoded.width, scanMaxSide);
  });

  test('CSV files are gzipped and unpack to the same text', () async {
    final csv = 'Description,Unit,Quantity,Rate\n${'Excavation,m3,10,1500\n' * 2000}';
    final bytes = Uint8List.fromList(utf8.encode(csv));

    final prepared = await prepareUpload(name: 'boq.csv', bytes: bytes);

    expect(prepared.name, 'boq.csv.gz');
    expect(prepared.size, lessThan(bytes.length ~/ 10));
    expect(utf8.decode(GZipDecoder().decodeBytes(prepared.bytes!)), csv);
  });

  test('small files and spreadsheets are sent unchanged', () async {
    final small = Uint8List.fromList(utf8.encode('Description,Qty\nA,1\n'));
    final prepared = await prepareUpload(name: 'tiny.csv', bytes: small);
    expect(prepared.name, 'tiny.csv');
    expect(prepared.compressed, isFalse);

    final xlsx = await prepareUpload(
      name: 'boq.xlsx',
      bytes: Uint8List.fromList([80, 75, 3, 4]),
    );
    expect(xlsx.name, 'boq.xlsx');
    expect(xlsx.bytes, isNotNull);
  });
}
