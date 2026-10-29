import '../../../models/announcement.dart';
import '../../api_client.dart';
import '../../offline.dart';
import '../announcements_repository.dart';

class HttpAnnouncementsRepository implements AnnouncementsRepository {
  HttpAnnouncementsRepository(this._api);
  final ApiClient _api;

  @override
  Future<AnnouncementFeed> feed({String filter = 'all'}) async {
    final data =
        await _api.get('/announcements/', query: {'filter': filter})
            as Map<String, dynamic>;
    return AnnouncementFeed(
      unread: data['unread'] as int,
      items: [
        for (final a in data['results'] as List)
          Announcement.fromJson(a as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> markRead(int id) async {
    try {
      await _api.sendOrQueue('POST', '/announcements/$id/read/', kind: 'read');
    } on QueuedOffline {
      // Sent later; nothing to tell the member.
    }
  }

  @override
  Future<Announcement> create({
    required String kind,
    required String title,
    required String body,
    int? eventId,
    bool pinned = false,
    List<int> tagged = const [],
  }) async => Announcement.fromJson(
    await _api.post(
          '/announcements/',
          body: {
            'kind': kind,
            'title': title,
            'body': body,
            'event': eventId,
            'pinned': pinned,
            'tagged': tagged,
          },
        )
        as Map<String, dynamic>,
  );

  @override
  Future<Announcement> update(
    int id, {
    required String kind,
    required String title,
    required String body,
    int? eventId,
    List<int> tagged = const [],
  }) async => Announcement.fromJson(
    await _api.patch(
          '/announcements/$id/',
          body: {
            'kind': kind,
            'title': title,
            'body': body,
            'event': eventId,
            'tagged': tagged,
          },
        )
        as Map<String, dynamic>,
  );

  @override
  Future<void> delete(int id) async => _api.delete('/announcements/$id/');

  @override
  Future<Announcement> get(int id) async => Announcement.fromJson(
    await _api.get('/announcements/$id/') as Map<String, dynamic>,
  );

  @override
  Future<List<ReadReceipt>> receipts(int id) async {
    final data =
        await _api.get('/announcements/$id/reads/') as Map<String, dynamic>;
    return [
      for (final r in data['rows'] as List)
        ReadReceipt(
          memberId: r['member'] as int,
          fullName: r['full_name'] as String,
          read: r['read'] as bool,
          tagged: (r['tagged'] as bool?) ?? false,
        ),
    ];
  }

  @override
  Future<List<Recipient>> recipients() async => [
    for (final r in await _api.get('/announcements/recipients/') as List)
      Recipient.fromJson(r as Map<String, dynamic>),
  ];

  @override
  Future<AttachmentInfo> attach(
    int announcementId, {
    required List<int> bytes,
    required String filename,
  }) async => AttachmentInfo.fromJson(
    await _api.postFile(
          '/announcements/$announcementId/attachments/',
          field: 'file',
          bytes: bytes,
          filename: filename,
        )
        as Map<String, dynamic>,
  );

  @override
  Future<int> remindUnread(int id) async =>
      ((await _api.post('/announcements/$id/remind/'))
              as Map<String, dynamic>)['reminded']
          as int;
}
