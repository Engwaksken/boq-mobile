import 'dart:convert';
import 'dart:typed_data';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => 'session-token';
}

class _ReceiptPicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => FilePickerResult([
    PlatformFile(
      name: 'receipt.pdf',
      size: 8,
      bytes: Uint8List.fromList(utf8.encode('%PDF-1.4')),
    ),
  ]);
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
ApiClient _api(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(storage: _Storage(), httpClient: MockClient(handler));
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('FAQ editing sends publication and ordering fields using PUT', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final api = _api((r) async {
      expect(r.method, 'PUT');
      expect(r.url.path, endsWith('/admin/faqs/5'));
      saved = jsonDecode(r.body) as Map<String, dynamic>;
      return _json({
        'data': {'id': 5},
      });
    });
    await tester.pumpWidget(
      _app(
        FaqFormPage(
          api: api,
          faq: {
            'id': 5,
            'question': 'Old question',
            'answer': 'Old answer',
            'sort_order': 2,
            'is_active': true,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Question'),
      'Updated question',
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, {
      'question': 'Updated question',
      'answer': 'Old answer',
      'sort_order': 2,
      'is_active': false,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('assignment revocation confirms then refreshes the list', (
    tester,
  ) async {
    var revoked = false;
    final api = _api((r) async {
      if (r.method == 'DELETE') {
        revoked = true;
        return http.Response('', 204);
      }
      return _json({
        'data': revoked
            ? []
            : [
                {
                  'id': 1,
                  'project_id': 8,
                  'user_id': 12,
                  'role': 'finance',
                  'project': {'name': 'Site A'},
                  'user': {'name': 'Alex', 'email': 'alex@example.test'},
                },
              ],
        'meta': {'current_page': 1, 'last_page': 1},
      });
    });
    await tester.pumpWidget(_app(ProjectAssignmentsPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    expect(revoked, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
    await tester.pumpAndSettle();
    expect(revoked, isTrue);
    expect(find.text('No records found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'receipt review saves multiple items and attachment retry never duplicates an expense',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      FilePicker.platform = _ReceiptPicker();
      var creates = 0;
      var uploads = 0;
      Map<String, dynamic>? saved;
      final api = _api((r) async {
        if (r.url.path.endsWith('/extract')) {
          return _json({
            'data': {
              'description': 'Cement',
              'quantity': 2,
              'unit': 'bags',
              'rate': 12.5,
              'purchase_date': '2026-10-01',
              'currency': 'USD',
              'warnings': ['Check supplier'],
            },
          });
        }
        if (r.url.path.endsWith('/receipts')) {
          uploads++;
          return uploads == 1
              ? _json({'message': 'Unavailable'}, 503)
              : _json({
                  'data': {'id': 7},
                }, 201);
        }
        if (r.method == 'POST') {
          creates++;
          saved = jsonDecode(r.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 4},
          }, 201);
        }
        return _json({
          'data': [
            {'id': 8, 'name': 'Assigned project', 'currency': 'USD'},
          ],
        });
      });
      await tester.pumpWidget(_app(ExpenseFormPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read receipt (PDF or image, up to 10 MB)'));
      await tester.pumpAndSettle();
      expect(find.text('Check supplier'), findsOneWidget);
      expect(creates, 0);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned project').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add expense item'));
      await tester.tap(find.text('Add expense item'));
      await tester.pumpAndSettle();
      for (final pair in [
        ('Description', 'Sand'),
        ('Quantity', '3'),
        ('Unit', 'loads'),
        ('Rate', '20'),
      ]) {
        final field = find.widgetWithText(TextFormField, pair.$1).last;
        await tester.ensureVisible(field);
        await tester.enterText(field, pair.$2);
      }
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(creates, 1);
      expect(uploads, 1);
      expect((saved!['items'] as List).length, 2);
      expect(saved!['items'][1]['description'], 'Sand');
      expect(saved!.containsKey('total'), isFalse);
      await tester.ensureVisible(
        find.text('Expense saved. Retry attaching receipt'),
      );
      await tester.tap(find.text('Expense saved. Retry attaching receipt'));
      await tester.pumpAndSettle();
      expect(creates, 1);
      expect(uploads, 2);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'assignment writes use scoped IDs and accept an empty 204 response',
    () async {
      final requests = <http.Request>[];
      final api = _api((r) async {
        requests.add(r);
        return r.method == 'DELETE'
            ? http.Response('', 204)
            : _json({
                'data': {'id': 1},
              }, 201);
      });
      await api.saveProjectAssignment(8, 12, 'finance');
      await api.revokeProjectAssignment(1);
      expect(jsonDecode(requests.first.body), {
        'project_id': 8,
        'user_id': 12,
        'role': 'finance',
      });
      expect(requests.last.url.path, endsWith('/project-assignments/1'));
    },
  );

  test(
    'receipt extraction enforces its own limit and sends authenticated multipart',
    () async {
      var sent = 0;
      final api = _api((r) async {
        sent++;
        expect(r.url.path, endsWith('/expenses/extract'));
        expect(r.headers['authorization'], 'Bearer session-token');
        expect(r.body, contains('name="file"'));
        return _json({
          'data': {
            'description': 'Cement',
            'warnings': ['Check rate'],
          },
        });
      });
      await expectLater(
        api.extractExpenseReceipt(
          Uint8List(10 * 1024 * 1024 + 1),
          'receipt.pdf',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(sent, 0);
      final data = await api.extractExpenseReceipt(
        Uint8List.fromList(utf8.encode('%PDF-1.4')),
        'receipt.pdf',
      );
      expect(data['warnings'], ['Check rate']);
    },
  );

  testWidgets('FAQ search resets pagination and expands answers', (
    tester,
  ) async {
    final queries = <Map<String, String>>[];
    final api = _api((r) async {
      queries.add(r.url.queryParameters);
      return _json({
        'data': [
          {
            'id': 1,
            'question': 'How to attach receipts?',
            'answer': 'Open the expense.',
          },
        ],
        'meta': {
          'current_page': int.parse(r.url.queryParameters['page']!),
          'last_page': 2,
        },
      });
    });
    await tester.pumpWidget(_app(FaqsPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to attach receipts?'));
    await tester.pumpAndSettle();
    expect(find.text('Open the expense.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'receipt & PDF');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(queries.last, {'page': '1', 'search': 'receipt & PDF'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'assignment form submits selected server project, member and role',
    (tester) async {
      Map<String, dynamic>? saved;
      final api = _api((r) async {
        if (r.method == 'POST') {
          saved = jsonDecode(r.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 1},
          }, 201);
        }
        return _json({
          'data': {
            'projects': [
              {'id': 8, 'name': 'Site A'},
            ],
            'members': [
              {'id': 12, 'name': 'Alex', 'email': 'alex@example.test'},
            ],
            'roles': ['finance'],
          },
        });
      });
      await tester.pumpWidget(_app(ProjectAssignmentFormPage(api: api)));
      await tester.pumpAndSettle();
      for (final pair in [
        (find.byType(DropdownButtonFormField<int>).at(0), 'Site A'),
        (
          find.byType(DropdownButtonFormField<int>).at(1),
          'Alex (alex@example.test)',
        ),
        (find.byType(DropdownButtonFormField<String>), 'finance'),
      ]) {
        await tester.tap(pair.$1);
        await tester.pumpAndSettle();
        await tester.tap(find.text(pair.$2).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, {'project_id': 8, 'user_id': 12, 'role': 'finance'});
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'project lookup follows pagination without dropping assigned projects',
    () async {
      final api = _api((r) async {
        final page = int.parse(r.url.queryParameters['page']!);
        return _json({
          'data': [
            {'id': page, 'name': 'Project $page'},
          ],
          'meta': {'last_page': 2},
        });
      });
      expect((await api.expenseProjects()).map((p) => p['id']), [1, 2]);
    },
  );

  test('updates and revocation use the Laravel PUT/DELETE contract', () async {
    final requests = <http.Request>[];
    final api = _api((r) async {
      requests.add(r);
      return _json({
        'data': {'id': 9},
      });
    });
    await api.saveExpense({
      'quantity': '3',
      'rate': '2',
      'is_planned': true,
    }, id: 9);
    await api.updateInvitation(7, {
      'email': 'new@example.test',
      'expires_at': '2026-12-01',
    });
    await api.revokeInvitation(7);
    expect(requests.map((r) => r.method), ['PUT', 'PUT', 'DELETE']);
    expect(requests[0].url.path, endsWith('/expenses/9'));
    expect(jsonDecode(requests[1].body).containsKey('role_id'), isFalse);
    expect(requests[2].url.path, endsWith('/invitations/7'));
  });

  testWidgets(
    'expense list opens detail and editing refreshes the server total',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final expense = <String, dynamic>{
        'id': 3,
        'project_id': 8,
        'description': 'Cement',
        'quantity': '2',
        'unit': 'bags',
        'rate': '12.5',
        'currency': 'USD',
        'total': '25.00',
        'is_planned': true,
        'purchase_date': '2026-10-01',
        'receipts': [
          {
            'id': 5,
            'original_filename': 'invoice.pdf',
            'mime_type': 'application/pdf',
          },
        ],
      };
      final api = _api((r) async {
        if (r.method == 'PUT') {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          expect(data.containsKey('project_id'), isFalse);
          expense.addAll(data);
          expense['total'] = '37.50';
          return _json({'data': expense});
        }
        if (r.url.path.endsWith('/projects')) {
          return _json({
            'data': [
              {'id': 8, 'name': 'Project', 'currency': 'USD'},
            ],
          });
        }
        if (r.url.path.endsWith('/expenses/3')) return _json({'data': expense});
        return _json({
          'data': [expense],
          'meta': {'current_page': 1, 'last_page': 1},
        });
      });
      await tester.pumpWidget(_app(ExpensesPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cement'));
      await tester.pumpAndSettle();
      expect(find.text('invoice.pdf'), findsOneWidget);
      expect(find.text('USD 25.00'), findsOneWidget);
      await tester.tap(find.text('Edit expense'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '3',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('USD 37.50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invitation revocation requires confirmation and refreshes its status',
    (tester) async {
      var revoked = false;
      final api = _api((r) async {
        if (r.method == 'DELETE') {
          revoked = true;
          return _json({
            'data': {'id': 2},
          });
        }
        return _json({
          'data': [
            {
              'id': 2,
              'email': 'member@example.test',
              'expires_at': DateTime.now()
                  .add(const Duration(days: 7))
                  .toIso8601String(),
              'revoked_at': revoked ? DateTime.now().toIso8601String() : null,
            },
          ],
          'meta': {'current_page': 1, 'last_page': 1},
        });
      });
      await tester.pumpWidget(_app(InvitationsPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke'));
      await tester.pumpAndSettle();
      expect(revoked, isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Revoke'));
      await tester.pumpAndSettle();
      expect(revoked, isTrue);
      expect(find.textContaining('Revoked ·'), findsOneWidget);
      expect(find.text('Revoke'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed form role lookup can be retried', (tester) async {
    var attempts = 0;
    final api = _api((r) async {
      attempts++;
      return attempts == 1
          ? _json({'message': 'Unavailable'}, 503)
          : _json({
              'data': [
                {'id': 1, 'name': 'User'},
              ],
            });
    });
    await tester.pumpWidget(_app(InvitationFormPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  test(
    'collections use resource metadata and preserve server-calculated decimal totals',
    () async {
      final api = _api((request) async {
        expect(request.headers['authorization'], 'Bearer session-token');
        expect(request.url.queryParameters['page'], '2');
        return _json({
          'data': [
            {'id': 3, 'total': '37.50', 'quantity': '3.000'},
          ],
          'meta': {'current_page': 2, 'last_page': 3},
        });
      });
      final page = await api.expenses(page: 2);
      expect(page.items.single['total'], '37.50');
      expect(page.page, 2);
      expect(page.hasNext, isTrue);
    },
  );

  test(
    'invitation create reads top-level token and acceptance trims it',
    () async {
      final api = _api((request) async {
        if (request.url.path.endsWith('/accept')) {
          expect(jsonDecode(request.body), {'token': 'single-use-token'});
          return _json({
            'data': {'accepted_at': '2026-10-05'},
          });
        }
        expect(jsonDecode(request.body)['role_id'], 17);
        return _json({
          'data': {'id': 1},
          'token': 'single-use-token',
        }, 201);
      });
      final token = await api.createInvitation({
        'email': 'member@example.test',
        'role_id': 17,
        'expires_at': '2026-11-01',
      });
      expect(token, 'single-use-token');
      await api.acceptInvitation('  $token  ');
    },
  );

  test(
    'receipt upload uses authenticated multipart and download uses our API origin',
    () async {
      final api = _api((request) async {
        expect(request.headers['authorization'], 'Bearer session-token');
        expect(request.url.origin, Uri.parse(ApiClient.baseUrl).origin);
        if (request.method == 'POST') {
          expect(request.url.path, endsWith('/expenses/12/receipts'));
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          expect(request.body, contains('name="file"'));
          expect(request.body, contains('%PDF-1.4'));
          return _json({
            'data': {'id': 7},
          }, 201);
        }
        expect(request.url.path, endsWith('/expense-receipts/7/download'));
        return http.Response('%PDF-1.4', 200);
      });
      await api.uploadExpenseReceipt(
        12,
        Uint8List.fromList(utf8.encode('%PDF-1.4')),
        'Receipt.pdf',
      );
      expect(utf8.decode(await api.downloadExpenseReceipt(7)), '%PDF-1.4');
    },
  );

  test('oversized receipts are rejected before an upload request', () async {
    final api = _api((request) async => throw StateError('Must not send'));
    await expectLater(
      api.uploadExpenseReceipt(
        1,
        Uint8List(20 * 1024 * 1024 + 1),
        'receipt.pdf',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  testWidgets(
    'unplanned expense requires a reason and never submits derived total or identity',
    (tester) async {
      Map<String, dynamic>? saved;
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _api((request) async {
        if (request.method == 'POST') {
          saved = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 4, 'total': '25.00'},
          }, 201);
        }
        return _json({
          'data': [
            {'id': 8, 'name': 'Assigned project', 'currency': 'USD'},
          ],
        });
      });
      await tester.pumpWidget(_app(ExpenseFormPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned project').last);
      await tester.pumpAndSettle();
      Future<void> fill(String label, String value) async {
        final finder = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, value);
      }

      await fill('Description', 'Cement');
      await fill('Quantity', '2');
      await fill('Unit', 'bags');
      await fill('Rate', '12.5');
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(find.text('Enter a valid value.'), findsOneWidget);
      await fill('Reason for unplanned purchase', 'Emergency repair');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved!['project_id'], 8);
      expect(saved!['currency'], 'USD');
      expect(saved!['is_planned'], isFalse);
      expect(saved!['explanation'], 'Emergency repair');
      for (final key in [
        'total',
        'purchaser_user_id',
        'creator_user_id',
        'organisation_id',
      ]) {
        expect(saved!.containsKey(key), isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invitation form uses role IDs from the server and reveals the token once',
    (tester) async {
      Map<String, dynamic>? saved;
      final api = _api((request) async {
        if (request.method == 'POST') {
          saved = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 9},
            'token': 'new-invitation-secret',
          }, 201);
        }
        return _json({
          'data': [
            {'id': 45, 'name': 'Finance', 'slug': 'finance'},
          ],
        });
      });
      await tester.pumpWidget(_app(InvitationFormPage(api: api)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'finance@example.test',
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finance').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved!['role_id'], 45);
      expect(DateTime.parse(saved!['expires_at'] as String).isUtc, isTrue);
      expect(find.text('new-invitation-secret'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invitation acceptance remains available when management is forbidden',
    (tester) async {
      var accepted = false;
      final api = _api((request) async {
        if (request.url.path.endsWith('/accept')) {
          accepted = true;
          return _json({
            'data': {'id': 2},
          });
        }
        return _json({'message': 'Forbidden'}, 403);
      });
      await tester.pumpWidget(_app(InvitationsPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept invitation'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'my-token');
      await tester.tap(find.widgetWithText(FilledButton, 'Accept invitation'));
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
      expect(
        find.text(
          'Invitation accepted. Your organisation access has been updated.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expense links a project to an approved BOQ and its approved items',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic>? saved;
      final boqQueries = <Map<String, String>>[];
      final itemQueries = <Map<String, String>>[];
      final api = _api((r) async {
        if (r.method == 'POST') {
          saved = jsonDecode(r.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 4, 'total': '25.00'},
          }, 201);
        }
        if (r.url.path.endsWith('/boqs/5/items')) {
          itemQueries.add(r.url.queryParameters);
          return _json({
            'data': {
              'data': [
                {
                  'id': 21,
                  'description': 'Cement',
                  'unit': 'bags',
                  'quantity': 10,
                },
                {
                  'id': 22,
                  'description': 'Sand',
                  'unit': 'loads',
                  'quantity': 5,
                },
              ],
              'last_page': 1,
            },
          });
        }
        if (r.url.path.endsWith('/boqs')) {
          boqQueries.add(r.url.queryParameters);
          return _json({
            'success': true,
            'data': {
              'data': [
                {
                  'id': 5,
                  'name': 'Main BOQ',
                  'code': 'BOQ-1',
                  'status': 'approved',
                  'project_id': 8,
                },
              ],
              'last_page': 1,
            },
          });
        }
        return _json({
          'data': [
            {'id': 8, 'name': 'Site A', 'currency': 'USD'},
          ],
        });
      });
      await tester.pumpWidget(_app(ExpenseFormPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<int>, 'Assigned project'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Site A').last);
      await tester.pumpAndSettle();

      // Both lookups must be scoped to approved records of the project.
      expect(boqQueries, isNotEmpty);
      expect(boqQueries.first['project_id'], '8');
      expect(boqQueries.first['status'], 'approved');
      expect(itemQueries, isNotEmpty);
      expect(itemQueries.first['status'], 'approved');
      // A lone approved BOQ is linked automatically.
      expect(find.text('Main BOQ'), findsOneWidget);

      Future<void> fill(String label, String value, {bool last = false}) async {
        var finder = find.widgetWithText(TextFormField, label);
        if (last) finder = finder.last;
        await tester.ensureVisible(finder);
        await tester.enterText(finder, value);
      }

      await fill('Description', 'Cement bags');
      await fill('Quantity', '2');
      await fill('Unit', 'bags');
      await fill('Rate', '12.5');

      Future<void> linkBoqItem(String item, {bool last = false}) async {
        var finder = find.widgetWithText(
          DropdownButtonFormField<int>,
          'BOQ item',
        );
        if (last) finder = finder.last;
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tester.tap(find.text(item).last);
        await tester.pumpAndSettle();
      }

      await linkBoqItem('Cement');
      await tester.ensureVisible(find.text('Add expense item'));
      await tester.tap(find.text('Add expense item'));
      await tester.pumpAndSettle();
      await fill('Description', 'Sand', last: true);
      await fill('Quantity', '3', last: true);
      await fill('Unit', 'loads', last: true);
      await fill('Rate', '20', last: true);
      await linkBoqItem('Sand', last: true);

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!['boq_id'], 5);
      final items = saved!['items'] as List;
      expect(items, hasLength(2));
      expect(items[0]['boq_item_id'], 21);
      expect(items[1]['boq_item_id'], 22);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'record-expense payment method dropdown saves the selected value',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic>? saved;
      final api = _api((r) async {
        if (r.method == 'POST') {
          saved = jsonDecode(r.body) as Map<String, dynamic>;
          return _json({
            'data': {'id': 4, 'total': '25.00'},
          }, 201);
        }
        return _json({
          'data': [
            {'id': 8, 'name': 'Assigned project', 'currency': 'USD'},
          ],
        });
      });
      await tester.pumpWidget(_app(ExpenseFormPage(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assigned project').last);
      await tester.pumpAndSettle();

      Future<void> fill(String label, String value) async {
        final finder = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, value);
      }

      await fill('Description', 'Cement');
      await fill('Quantity', '2');
      await fill('Unit', 'bags');
      await fill('Rate', '12.5');

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile Money').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!['payment_method'], 'Mobile Money');
      expect(tester.takeException(), isNull);
    },
  );
}
