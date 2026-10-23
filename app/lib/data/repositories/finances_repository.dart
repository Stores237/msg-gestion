import '../../models/finance.dart';

abstract class FinancesRepository {
  Future<FinanceSummary> summary();
  Future<List<FinanceEntry>> entries();

  /// Idempotent on [NewEntry.clientUuid]: safe to retry.
  Future<FinanceEntry> createEntry(NewEntry entry);
  Future<FinanceEntry> validate(int id);
  Future<List<Collection>> collections();
  Future<Collection> collection(int id);
  Future<Collection> openCollection({
    required String kind,
    required String title,
    required int amountPerMember,
  });

  /// member id → amount
  Future<void> pay(int collectionId, Map<int, int> payments);
  Future<void> closeCollection(int id);
  Future<MyDues> mine();
  Future<QuarterReport> report(int year, int quarter);
  Future<QuarterReport> validateReport(int year, int quarter);

  /// Signed download links for the PDF exports.
  Future<String> reportPdf(int year, int quarter);
  Future<String> cashbookPdf();

  /// Bilan: every member's dues and payments, or one member's.
  Future<String> statementPdf();
  Future<String> memberStatementPdf(int memberId);
}
