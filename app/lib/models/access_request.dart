/// A group leader's request for someone's access, processed by the
/// platform's partner in the back-office.
class AccessRequestItem {
  const AccessRequestItem({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.roleName,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.decisionNote = '',
    this.decidedAt,
    this.pinReady = false,
  });

  final int id;
  final String fullName;
  final String phone;
  final String role;
  final String roleName;

  /// pending | approved | refused
  final String status;
  final String note;
  final String decisionNote;
  final DateTime createdAt;
  final DateTime? decidedAt;

  /// The temporary PIN is waiting to be seen (once).
  final bool pinReady;

  bool get pending => status == 'pending';
  bool get approved => status == 'approved';

  factory AccessRequestItem.fromJson(Map<String, dynamic> j) =>
      AccessRequestItem(
        id: j['id'] as int,
        fullName: j['full_name'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
        roleName: j['role_name'] as String,
        status: j['status'] as String,
        note: (j['note'] as String?) ?? '',
        decisionNote: (j['decision_note'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        decidedAt: j['decided_at'] == null
            ? null
            : DateTime.parse(j['decided_at'] as String),
        pinReady: j['pin_ready'] as bool? ?? false,
      );
}

/// What the leader hands over to the new member.
class AccessPin {
  const AccessPin({
    required this.fullName,
    required this.phone,
    required this.pin,
  });
  final String fullName;
  final String phone;
  final String pin;

  factory AccessPin.fromJson(Map<String, dynamic> j) => AccessPin(
    fullName: j['full_name'] as String,
    phone: j['phone'] as String,
    pin: j['pin'] as String,
  );
}
