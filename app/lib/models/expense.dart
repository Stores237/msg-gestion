/// Expense requests (owner, 2026-10-30): a member asks; the domain's lead
/// (or a tagged coordinator) approves; the commissaire approves; the
/// trésorier pays and posts the proof in the thread.
class ExpenseDomain {
  const ExpenseDomain({required this.id, required this.name, this.leadRole});
  final int id;
  final String name;

  /// The role that approves first ("Formateur"); null = a tagged coordinator.
  final String? leadRole;

  factory ExpenseDomain.fromJson(Map<String, dynamic> j) => ExpenseDomain(
    id: j['id'] as int,
    name: j['name'] as String,
    leadRole: j['lead_role'] as String?,
  );
}

class ExpenseMessage {
  const ExpenseMessage({
    required this.id,
    required this.kind,
    required this.body,
    this.authorName,
    this.fileName = '',
    this.contentType = '',
    this.fileUrl,
    required this.createdAt,
  });
  final int id;

  /// step | comment | proof
  final String kind;
  final String body;
  final String? authorName;
  final String fileName;
  final String contentType;
  final String? fileUrl;
  final DateTime createdAt;

  bool get isImage => contentType.startsWith('image/');

  factory ExpenseMessage.fromJson(Map<String, dynamic> j) => ExpenseMessage(
    id: j['id'] as int,
    kind: j['kind'] as String,
    body: (j['body'] as String?) ?? '',
    authorName: j['author_name'] as String?,
    fileName: (j['file_name'] as String?) ?? '',
    contentType: (j['content_type'] as String?) ?? '',
    fileUrl: j['file_url'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}

class ExpenseRequest {
  const ExpenseRequest({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.domainName,
    required this.status,
    required this.requesterName,
    this.taggedNames = const [],
    this.leadByName,
    this.auditByName,
    this.paidByName,
    this.paidAmount,
    this.closeReason = '',
    this.replaces,
    this.replacedBy,
    required this.createdAt,
    this.actions = const [],
    this.messages = const [],
    this.domainId,
  });
  final int id;
  final String title;
  final String description;
  final int amount;
  final int? domainId;
  final String domainName;

  /// submitted | approved | to_pay | paid | refused | cancelled
  final String status;
  final String requesterName;
  final List<String> taggedNames;
  final String? leadByName;
  final String? auditByName;
  final String? paidByName;
  final int? paidAmount;
  final String closeReason;
  final int? replaces;
  final int? replacedBy;
  final DateTime createdAt;

  /// What the viewer may do now: decide, audit, pay, cancel, resubmit.
  final List<String> actions;
  final List<ExpenseMessage> messages;

  bool get open =>
      status == 'submitted' || status == 'approved' || status == 'to_pay';

  factory ExpenseRequest.fromJson(Map<String, dynamic> j) => ExpenseRequest(
    id: j['id'] as int,
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    amount: j['amount'] as int,
    domainId: j['domain'] as int?,
    domainName: j['domain_name'] as String,
    status: j['status'] as String,
    requesterName: j['requester_name'] as String,
    taggedNames: [for (final n in (j['tagged_names'] as List?) ?? []) '$n'],
    leadByName: j['lead_by_name'] as String?,
    auditByName: j['audit_by_name'] as String?,
    paidByName: j['paid_by_name'] as String?,
    paidAmount: j['paid_amount'] as int?,
    closeReason: (j['close_reason'] as String?) ?? '',
    replaces: j['replaces'] as int?,
    replacedBy: j['replaced_by'] as int?,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    actions: [for (final a in (j['actions'] as List?) ?? []) '$a'],
    messages: [
      for (final m in (j['messages'] as List?) ?? [])
        ExpenseMessage.fromJson(m as Map<String, dynamic>),
    ],
  );
}

/// A file joined to a message or the proof: name and bytes.
typedef PickedFile = ({String name, List<int> bytes});
