import '../../models/expense.dart';
import '../../models/finance.dart';

abstract class FinancesRepository {
  Future<FinanceSummary> summary();
  Future<List<FinanceEntry>> entries();

  /// Idempotent on [NewEntry.clientUuid]: safe to retry.
  Future<FinanceEntry> createEntry(NewEntry entry);
  Future<FinanceEntry> validate(int id);

  /// Several at once (long press, owner 2026-10-30). Lines this person
  /// can't approve are left as they are: [skipped] counts them.
  Future<({List<int> validated, int skipped})> validateMany(List<int> ids);

  /// The trésorier or the commissaire corrects a line not yet validated
  /// (direction, amount, category, label, member, date); the other one
  /// then approves it.
  Future<FinanceEntry> editEntry(int id, NewEntry changes);

  /// The commissaire finalises a line the trésorier edited and validated,
  /// or sends it back ([reason] required).
  Future<FinanceEntry> confirmEntry(
    int id, {
    required bool accept,
    String reason = '',
  });
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

  // --- Expense requests (owner, 2026-10-30) ---
  Future<List<ExpenseDomain>> expenseDomains();

  /// [box]: todo (waiting for me) | mine | all.
  Future<List<ExpenseRequest>> expenses(String box);
  Future<ExpenseRequest> expense(int id);
  Future<ExpenseRequest> newExpense({
    required int domainId,
    required String title,
    required int amount,
    String description = '',
    List<int> tagged = const [],
    int? replaces,
  });

  /// [step]: decide | review | cancel ([note] is the reason to refuse or
  /// cancel).
  Future<ExpenseRequest> expenseStep(
    int id,
    String step, {
    bool approve = false,
    String note = '',
  });
  Future<ExpenseRequest> payExpense(
    int id, {
    required int amount,
    required PickedFile proof,
    String note = '',
  });

  /// [initial]: a file joined on the request form (no second notice).
  Future<ExpenseRequest> expenseMessage(
    int id, {
    String body = '',
    PickedFile? file,
    bool initial = false,
  });
}
