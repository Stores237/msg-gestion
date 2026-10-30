import '../../../models/expense.dart';
import '../../../models/finance.dart';
import '../../api_client.dart';
import '../../current_user.dart';
import '../../offline.dart';
import '../finances_repository.dart';

class HttpFinancesRepository implements FinancesRepository {
  HttpFinancesRepository(this._api);
  final ApiClient _api;

  @override
  Future<FinanceSummary> summary() async => FinanceSummary.fromJson(
    await _api.get('/finances/summary/') as Map<String, dynamic>,
  );

  @override
  Future<List<FinanceEntry>> entries() async => [
    // Entered offline, not sent yet: shown first, marked "Pas encore envoyé".
    for (final item in OfflineState.instance.outbox.reversed)
      if (item.kind == 'entry')
        _local(item.body as Map<String, dynamic>, item.createdAt),
    for (final e in await _api.get('/finances/entries/') as List)
      FinanceEntry.fromJson(e as Map<String, dynamic>),
  ];

  /// Several ticked members: one row "N × amount" until it is sent.
  FinanceEntry _local(Map<String, dynamic> body, DateTime at) => FinanceEntry(
    id: -at.microsecondsSinceEpoch,
    direction: body['direction'] as String,
    amount: (body['amount'] as int) * ((body['members'] as List?)?.length ?? 1),
    category: body['category'] as String,
    label: body['label'] as String,
    memberId: body['member'] as int?,
    memberName: body['member_name'] as String?,
    date: DateTime.parse(body['date'] as String),
    status: 'pending',
    clientUuid: body['client_uuid'] as String?,
    createdByName: currentUser.value?.fullName ?? '',
    createdAt: at,
    local: true,
  );

  @override
  Future<FinanceEntry> createEntry(NewEntry entry) async {
    // member_name rides along for the offline row; the server ignores it.
    final body = {
      ...entry.toJson(),
      'member_name': entry.memberNames.isEmpty
          ? entry.memberName
          : entry.memberNames.join(', '),
    };
    try {
      final j =
          await _api.sendOrQueue(
                'POST',
                '/finances/entries/',
                body: body,
                kind: 'entry',
              )
              as Map<String, dynamic>;
      // Several members: {"entries": [...], "count": n}.
      final rows = j['entries'] as List?;
      return FinanceEntry.fromJson(
        rows == null ? j : rows.first as Map<String, dynamic>,
      );
    } on QueuedOffline catch (q) {
      return _local(body, q.item.createdAt);
    }
  }

  @override
  Future<FinanceEntry> validate(int id) async => FinanceEntry.fromJson(
    await _api.post('/finances/entries/$id/validate/') as Map<String, dynamic>,
  );

  @override
  Future<({List<int> validated, int skipped})> validateMany(
    List<int> ids,
  ) async {
    final data =
        await _api.post('/finances/entries/validate/', body: {'ids': ids})
            as Map<String, dynamic>;
    return (
      validated: [for (final i in data['validated'] as List) i as int],
      skipped: (data['skipped'] as List).length,
    );
  }

  @override
  Future<FinanceEntry> editEntry(int id, NewEntry changes) async {
    final body = changes.toJson()..remove('client_uuid');
    return FinanceEntry.fromJson(
      await _api.patch('/finances/entries/$id/', body: body)
          as Map<String, dynamic>,
    );
  }

  @override
  Future<FinanceEntry> confirmEntry(
    int id, {
    required bool accept,
    String reason = '',
  }) async => FinanceEntry.fromJson(
    await _api.post(
          '/finances/entries/$id/confirm/',
          body: {'accept': accept, 'reason': reason},
        )
        as Map<String, dynamic>,
  );

  @override
  Future<List<Collection>> collections() async => [
    for (final c in await _api.get('/finances/collections/') as List)
      Collection.fromJson(c as Map<String, dynamic>),
  ];

  @override
  Future<Collection> collection(int id) async => Collection.fromJson(
    await _api.get('/finances/collections/$id/') as Map<String, dynamic>,
  );

  @override
  Future<Collection> openCollection({
    required String kind,
    required String title,
    required int amountPerMember,
  }) async => Collection.fromJson(
    await _api.post(
          '/finances/collections/',
          body: {
            'kind': kind,
            'title': title,
            'amount_per_member': amountPerMember,
          },
        )
        as Map<String, dynamic>,
  );

  @override
  Future<void> pay(int collectionId, Map<int, int> payments) =>
      _api.sendOrQueue(
        'POST',
        '/finances/collections/$collectionId/payments/',
        kind: 'payments',
        body: {
          'payments': [
            for (final e in payments.entries)
              {'member': e.key, 'amount': e.value, 'client_uuid': uuidV4()},
          ],
        },
      );

  @override
  Future<void> closeCollection(int id) =>
      _api.post('/finances/collections/$id/close/');

  @override
  Future<MyDues> mine() async {
    final j = await _api.get('/finances/mine/') as Map<String, dynamic>;
    return MyDues(
      toPay: j['to_pay'] as int,
      dues: [
        for (final d in j['dues'] as List)
          Due.fromJson(d as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<QuarterReport> report(int year, int quarter) async =>
      QuarterReport.fromJson(
        await _api.get(
              '/finances/report/',
              query: {'year': '$year', 'quarter': '$quarter'},
            )
            as Map<String, dynamic>,
      );

  @override
  Future<QuarterReport> validateReport(int year, int quarter) async =>
      QuarterReport.fromJson(
        await _api.post(
              '/finances/report/validate/',
              body: {'year': year, 'quarter': quarter},
            )
            as Map<String, dynamic>,
      );

  @override
  Future<String> reportPdf(int year, int quarter) async =>
      ((await _api.get(
                '/finances/report/pdf/',
                query: {'year': '$year', 'quarter': '$quarter'},
              ))
              as Map<String, dynamic>)['url']
          as String;

  @override
  Future<String> cashbookPdf() async =>
      ((await _api.get('/finances/entries/pdf/'))
              as Map<String, dynamic>)['url']
          as String;

  @override
  Future<String> statementPdf() async =>
      ((await _api.get('/finances/statement/pdf/'))
              as Map<String, dynamic>)['url']
          as String;

  @override
  Future<String> memberStatementPdf(int memberId) async =>
      ((await _api.get('/finances/statement/$memberId/pdf/'))
              as Map<String, dynamic>)['url']
          as String;

  @override
  Future<List<ExpenseDomain>> expenseDomains() async => [
    for (final d in await _api.get('/finances/expense-domains/') as List)
      ExpenseDomain.fromJson(d as Map<String, dynamic>),
  ];

  @override
  Future<List<ExpenseRequest>> expenses(String box) async => [
    for (final r in await _api.get('/finances/expenses/?box=$box') as List)
      ExpenseRequest.fromJson(r as Map<String, dynamic>),
  ];

  @override
  Future<ExpenseRequest> expense(int id) async => ExpenseRequest.fromJson(
    await _api.get('/finances/expenses/$id/') as Map<String, dynamic>,
  );

  @override
  Future<ExpenseRequest> newExpense({
    required int domainId,
    required String title,
    required int amount,
    String description = '',
    List<int> tagged = const [],
    int? replaces,
  }) async => ExpenseRequest.fromJson(
    await _api.post(
          '/finances/expenses/',
          body: {
            'domain': domainId,
            'title': title,
            'amount': amount,
            'description': description,
            'tagged': tagged,
            'replaces': ?replaces,
          },
        )
        as Map<String, dynamic>,
  );

  @override
  Future<ExpenseRequest> expenseStep(
    int id,
    String step, {
    bool approve = false,
    String note = '',
  }) async => ExpenseRequest.fromJson(
    await _api.post(
          '/finances/expenses/$id/$step/',
          body: {'approve': approve, 'note': note},
        )
        as Map<String, dynamic>,
  );

  @override
  Future<ExpenseRequest> payExpense(
    int id, {
    required int amount,
    required PickedFile proof,
    String note = '',
  }) async => ExpenseRequest.fromJson(
    await _api.postFile(
          '/finances/expenses/$id/pay/',
          field: 'file',
          bytes: proof.bytes,
          filename: proof.name,
          fields: {'amount': '$amount', 'note': note},
        )
        as Map<String, dynamic>,
  );

  @override
  Future<ExpenseRequest> expenseMessage(
    int id, {
    String body = '',
    PickedFile? file,
  }) async => ExpenseRequest.fromJson(
    (file == null
            ? await _api.post(
                '/finances/expenses/$id/messages/',
                body: {'body': body},
              )
            : await _api.postFile(
                '/finances/expenses/$id/messages/',
                field: 'file',
                bytes: file.bytes,
                filename: file.name,
                fields: {'body': body},
              ))
        as Map<String, dynamic>,
  );
}
