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

  FinanceEntry _local(Map<String, dynamic> body, DateTime at) => FinanceEntry(
    id: -at.microsecondsSinceEpoch,
    direction: body['direction'] as String,
    amount: body['amount'] as int,
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
    final body = {...entry.toJson(), 'member_name': entry.memberName};
    try {
      return FinanceEntry.fromJson(
        await _api.sendOrQueue(
              'POST',
              '/finances/entries/',
              body: body,
              kind: 'entry',
            )
            as Map<String, dynamic>,
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
}
