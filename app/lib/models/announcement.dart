class AttachmentInfo {
  const AttachmentInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.contentType,
    required this.url,
  });
  final int id;
  final String name;
  final int size;
  final String contentType;
  final String url;

  bool get isPdf => contentType == 'application/pdf';

  factory AttachmentInfo.fromJson(Map<String, dynamic> j) => AttachmentInfo(
    id: j['id'] as int,
    name: j['name'] as String,
    size: j['size'] as int,
    contentType: j['content_type'] as String,
    url: j['url'] as String,
  );
}

class Announcement {
  const Announcement({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.eventId,
    this.eventTitle,
    this.eventStartsAt,
    required this.pinned,
    this.authorName,
    this.authorRole = '',
    this.canEdit = false,
    this.canDelete = false,
    required this.createdAt,
    required this.unread,
    this.readCount,
    this.audience,
    this.attachments = const [],
  });

  final int id;

  /// annonce | convocation
  final String kind;
  final String title;
  final String body;
  final int? eventId;
  final String? eventTitle;
  final DateTime? eventStartsAt;
  final bool pinned;
  final String? authorName;

  /// The author's role when they posted ("Trésorier", "Président du jour").
  final String authorRole;

  /// The viewer may edit / delete it (their own, or they manage posts).
  final bool canEdit;
  final bool canDelete;
  final DateTime createdAt;
  final bool unread;

  /// Only for the author / people who manage announcements.
  final int? readCount;
  final int? audience;
  final List<AttachmentInfo> attachments;

  bool get isConvocation => kind == 'convocation';

  Announcement copyWith({bool? unread}) => Announcement(
    id: id,
    kind: kind,
    title: title,
    body: body,
    eventId: eventId,
    eventTitle: eventTitle,
    eventStartsAt: eventStartsAt,
    pinned: pinned,
    authorName: authorName,
    authorRole: authorRole,
    canEdit: canEdit,
    canDelete: canDelete,
    createdAt: createdAt,
    unread: unread ?? this.unread,
    readCount: readCount,
    audience: audience,
    attachments: attachments,
  );

  factory Announcement.fromJson(Map<String, dynamic> j) {
    final reads = j['reads'] as Map<String, dynamic>?;
    return Announcement(
      id: j['id'] as int,
      kind: j['kind'] as String,
      title: j['title'] as String,
      body: (j['body'] as String?) ?? '',
      eventId: j['event'] as int?,
      eventTitle: j['event_title'] as String?,
      eventStartsAt: j['event_starts_at'] == null
          ? null
          : DateTime.parse(j['event_starts_at'] as String).toLocal(),
      pinned: j['pinned'] as bool,
      authorName: j['author_name'] as String?,
      authorRole: (j['author_role'] as String?) ?? '',
      canEdit: (j['can_edit'] as bool?) ?? false,
      canDelete: (j['can_delete'] as bool?) ?? false,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      unread: j['unread'] as bool,
      readCount: reads?['read'] as int?,
      audience: reads?['total'] as int?,
      attachments: [
        for (final a in (j['attachments'] as List?) ?? const [])
          AttachmentInfo.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}

class AnnouncementFeed {
  const AnnouncementFeed({required this.unread, required this.items});
  final int unread;
  final List<Announcement> items;
}

class ReadReceipt {
  const ReadReceipt({
    required this.memberId,
    required this.fullName,
    required this.read,
  });
  final int memberId;
  final String fullName;
  final bool read;
}
