import 'dart:math';

/// Amounts are whole FCFA; signed helpers live in widgets/money.dart.
class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.direction,
    required this.amount,
    required this.category,
    required this.label,
    this.memberId,
    this.memberName,
    required this.date,
    required this.status,
    this.clientUuid,
    required this.createdByName,
    required this.createdAt,
    this.validatedByName,
    this.validatedAt,
    this.local = false,
  });

  final int id;

  /// in | out
  final String direction;
  final int amount;

  /// inscription | amende | aide_don | solidarite | depense
  final String category;
  final String label;
  final int? memberId;
  final String? memberName;
  final DateTime date;

  /// pending | validated
  final String status;
  final String? clientUuid;
  final String createdByName;
  final DateTime createdAt;
  final String? validatedByName;
  final DateTime? validatedAt;

  /// Entered offline and not yet on the server (design: "Pas encore envoyé").
  final bool local;

  bool get isIn => direction == 'in';
  bool get pending => status == 'pending';

  factory FinanceEntry.fromJson(Map<String, dynamic> j) => FinanceEntry(
    id: j['id'] as int,
    direction: j['direction'] as String,
    amount: j['amount'] as int,
    category: j['category'] as String,
    label: j['label'] as String,
    memberId: j['member'] as int?,
    memberName: j['member_name'] as String?,
    date: DateTime.parse(j['date'] as String),
    status: j['status'] as String,
    clientUuid: j['client_uuid'] as String?,
    createdByName: (j['created_by_name'] as String?) ?? '',
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    validatedByName: j['validated_by_name'] as String?,
    validatedAt: j['validated_at'] == null
        ? null
        : DateTime.parse(j['validated_at'] as String).toLocal(),
  );
}

/// What the treasurer types; also the offline queue's payload.
class NewEntry {
  NewEntry({
    required this.direction,
    required this.amount,
    required this.category,
    required this.label,
    this.memberId,
    this.memberName,
    required this.date,
    String? clientUuid,
  }) : clientUuid = clientUuid ?? uuidV4();

  final String direction;
  final int amount;
  final String category;
  final String label;
  final int? memberId;
  final String? memberName;
  final DateTime date;
  final String clientUuid;

  Map<String, dynamic> toJson() => {
    'direction': direction,
    'amount': amount,
    'category': category,
    'label': label,
    'member': memberId,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'client_uuid': clientUuid,
  };
}

/// RFC 4122 v4, so an entry retried after a dropped connection is recorded
/// once (the server keys on it).
String uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

class FinanceSummary {
  const FinanceSummary({
    required this.balance,
    required this.balanceWithPending,
    required this.pending,
    this.validatedUntil,
  });
  final int balance;
  final int balanceWithPending;
  final int pending;
  final DateTime? validatedUntil;

  factory FinanceSummary.fromJson(Map<String, dynamic> j) => FinanceSummary(
    balance: j['balance'] as int,
    balanceWithPending: j['balance_with_pending'] as int,
    pending: j['pending'] as int,
    validatedUntil: j['validated_until'] == null
        ? null
        : DateTime.parse(j['validated_until'] as String),
  );
}

class Collection {
  const Collection({
    required this.id,
    required this.kind,
    required this.title,
    required this.amountPerMember,
    required this.tranches,
    required this.paidFull,
    required this.members,
    required this.collected,
    required this.openedOn,
    this.closed = false,
    this.rows = const [],
  });

  final int id;
  final String kind;
  final String title;
  final int amountPerMember;
  final List<int> tranches;
  final int paidFull;
  final int members;
  final int collected;
  final DateTime openedOn;
  final bool closed;
  final List<CollectionRow> rows;

  /// [834, 1667, 2500] → [834, 833, 833]
  List<int> get parts => [
    for (var i = 0; i < tranches.length; i++)
      tranches[i] - (i == 0 ? 0 : tranches[i - 1]),
  ];

  factory Collection.fromJson(Map<String, dynamic> j) => Collection(
    id: j['id'] as int,
    kind: j['kind'] as String,
    title: j['title'] as String,
    amountPerMember: j['amount_per_member'] as int,
    tranches: List<int>.from(j['tranches'] as List),
    paidFull: j['paid_full'] as int,
    members: j['members'] as int,
    collected: j['collected'] as int,
    openedOn: DateTime.parse(j['opened_on'] as String),
    closed: j['closed_at'] != null,
    rows: [
      for (final r in (j['rows'] as List?) ?? const [])
        CollectionRow.fromJson(r as Map<String, dynamic>),
    ],
  );
}

class CollectionRow {
  const CollectionRow({
    required this.memberId,
    required this.fullName,
    required this.isDiaspora,
    required this.paid,
    required this.thirds,
    required this.nextAmount,
  });
  final int memberId;
  final String fullName;
  final bool isDiaspora;
  final int paid;
  final int thirds;
  final int nextAmount;

  bool get done => nextAmount == 0;

  factory CollectionRow.fromJson(Map<String, dynamic> j) => CollectionRow(
    memberId: j['member'] as int,
    fullName: j['full_name'] as String,
    isDiaspora: j['is_diaspora'] as bool,
    paid: j['paid'] as int,
    thirds: j['thirds'] as int,
    nextAmount: j['next_amount'] as int,
  );
}

class Due {
  const Due({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
    required this.paid,
    required this.remaining,
  });
  final int id;
  final String kind;
  final String label;
  final int amount;
  final int paid;
  final int remaining;

  factory Due.fromJson(Map<String, dynamic> j) => Due(
    id: j['id'] as int,
    kind: j['kind'] as String,
    label: j['label'] as String,
    amount: j['amount'] as int,
    paid: j['paid'] as int,
    remaining: j['remaining'] as int,
  );
}

class MyDues {
  const MyDues({required this.toPay, required this.dues});
  final int toPay;
  final List<Due> dues;
}

class QuarterReport {
  const QuarterReport({
    required this.year,
    required this.quarter,
    required this.start,
    required this.end,
    required this.opening,
    required this.income,
    required this.expense,
    required this.closing,
    required this.incomeByCategory,
    required this.pending,
    this.validatedBy,
    this.validatedAt,
  });

  final int year;
  final int quarter;
  final DateTime start;
  final DateTime end;
  final int opening;
  final int income;
  final int expense;
  final int closing;
  final Map<String, int> incomeByCategory;
  final int pending;
  final String? validatedBy;
  final DateTime? validatedAt;

  factory QuarterReport.fromJson(Map<String, dynamic> j) => QuarterReport(
    year: j['year'] as int,
    quarter: j['quarter'] as int,
    start: DateTime.parse(j['start'] as String),
    end: DateTime.parse(j['end'] as String),
    opening: j['opening'] as int,
    income: j['in'] as int,
    expense: j['out'] as int,
    closing: j['closing'] as int,
    incomeByCategory: (j['in_by_category'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
    pending: j['pending'] as int,
    validatedBy: j['validated_by'] as String?,
    validatedAt: j['validated_at'] == null
        ? null
        : DateTime.parse(j['validated_at'] as String).toLocal(),
  );
}
