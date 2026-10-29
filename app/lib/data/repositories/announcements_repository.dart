import '../../models/announcement.dart';

abstract class AnnouncementsRepository {
  /// [filter]: all | convocations | unread | sent | for_me
  Future<AnnouncementFeed> feed({String filter = 'all'});
  Future<void> markRead(int id);
  Future<Announcement> create({
    required String kind,
    required String title,
    required String body,
    int? eventId,
    bool pinned = false,
    List<int> tagged = const [],
  });

  /// The author (or someone who manages announcements) edits or deletes it.
  Future<Announcement> update(
    int id, {
    required String kind,
    required String title,
    required String body,
    int? eventId,
    List<int> tagged = const [],
  });
  Future<void> delete(int id);
  Future<Announcement> get(int id);

  Future<List<ReadReceipt>> receipts(int id);

  /// Who an announcement can be for (the author's "Notifier" picker).
  Future<List<Recipient>> recipients();

  /// Upload a PDF/JPEG/PNG (≤ 10 MB) to an announcement you wrote.
  Future<AttachmentInfo> attach(
    int announcementId, {
    required List<int> bytes,
    required String filename,
  });

  /// Notify those who haven't read it yet (only the tagged members when
  /// it names some); returns how many.
  Future<int> remindUnread(int id);
}
