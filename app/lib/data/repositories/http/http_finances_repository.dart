import '../../../models/finance.dart';
import '../../api_client.dart';
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
    for (final e in await _api.get('/finances/entries/') as List)
      FinanceEntry.fromJson(e as Map<String, dynamic>),
  ];

  @override
  Future<FinanceEntry> createEntry(NewEntry entry) async =>
      FinanceEntry.fromJson(
        await _api.post('/finances/entries/', body: entry.toJson())
            as Map<String, dynamic>,
      );

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
  Future<void> pay(int collectionId, Map<int, int> payments) => _api.post(
    '/finances/collections/$collectionId/payments/',
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
}
