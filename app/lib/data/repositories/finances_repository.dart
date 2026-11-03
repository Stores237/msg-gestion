import '../../models/me.dart';
import '../../models/expense.dart';
import '../../models/finance.dart';

/// The period chosen for a finance export (owner, 2026-11-03), both days
/// included; null ends = open.
class ExportPeriod {
  const ExportPeriod({this.from, this.to});
  final DateTime? from;
  final DateTime? to;

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// ?from=…&to=… for the API.
  Map<String, String> get query => {
    if (from != null) 'from': _day(from!),
    if (to != null) 'to': _day(to!),
  };

  /// "2026-10-01_2026-10-31": in file names and offline keys.
  String get slug => [from, to].map((d) => d == null ? '' : _day(d)).join('_');
}

/// A contribution between levels of a network (build 44). [group] is the
/// other side: the group above (owed) or the group below (asked).
class NetworkDueItem {
  const NetworkDueItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.group,
    this.currency = 'FCFA',
    this.dueOn,
    this.status = 'open',
    this.late = false,
    this.cancelReason = '',
  });
  final int id;
  final String title;
  final int amount;
  final String currency;
  final GroupInfo group;
  final DateTime? dueOn;

  /// open | sent | received | cancelled
  final String status;
  final bool late;
  final String cancelReason;

  factory NetworkDueItem.fromJson(Map<String, dynamic> j) => NetworkDueItem(
    id: j['id'] as int,
    title: j['title'] as String,
    amount: j['amount'] as int,
    currency: (j['currency'] as String?) ?? 'FCFA',
    group: GroupInfo.fromJson(j['group'] as Map<String, dynamic>),
    dueOn: j['due_on'] == null ? null : DateTime.parse(j['due_on'] as String),
    status: (j['status'] as String?) ?? 'open',
    late: j['late'] == true,
    cancelReason: (j['cancel_reason'] as String?) ?? '',
  );
}

class NetworkDues {
  const NetworkDues({
    this.owed = const [],
    this.asked = const [],
    this.canPay = false,
    this.canAsk = false,
  });
  final List<NetworkDueItem> owed;
  final List<NetworkDueItem> asked;
  final bool canPay;
  final bool canAsk;

  factory NetworkDues.fromJson(Map<String, dynamic> j) => NetworkDues(
    owed: [
      for (final d in (j['owed'] as List?) ?? const [])
        NetworkDueItem.fromJson(d as Map<String, dynamic>),
    ],
    asked: [
      for (final d in (j['asked'] as List?) ?? const [])
        NetworkDueItem.fromJson(d as Map<String, dynamic>),
    ],
    canPay: j['can_pay'] == true,
    canAsk: j['can_ask'] == true,
  );
}

abstract class FinancesRepository {
  /// Contributions between levels (build 44).
  Future<NetworkDues> networkDues();
  Future<NetworkDues> askNetworkDue({
    required String title,
    required int amount,
    DateTime? dueOn,
  });
  Future<NetworkDues> payNetworkDue(int id);
  Future<NetworkDues> cancelNetworkDue(int id, String reason);

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
  Future<String> cashbookPdf({ExportPeriod? period});

  /// Bilan: every member's dues and payments, or one member's.
  Future<String> statementPdf({ExportPeriod? period});
  Future<String> memberStatementPdf(int memberId, {ExportPeriod? period});

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
