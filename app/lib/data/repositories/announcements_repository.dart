import '../../models/announcement.dart';

abstract class AnnouncementsRepository {
  /// [filter]: all | convocations | unread | sent
  Future<AnnouncementFeed> feed({String filter = 'all'});
  Future<void> markRead(int id);
  Future<Announcement> create({
    required String kind,
    required String title,
    required String body,
    int? eventId,
    bool pinned = false,
  });
  Future<List<ReadReceipt>> receipts(int id);

  /// Upload a PDF/JPEG/PNG (≤ 10 MB) to an announcement you wrote.
  Future<AttachmentInfo> attach(
    int announcementId, {
    required List<int> bytes,
    required String filename,
  });

  /// Notify everyone who hasn't read it yet; returns how many.
  Future<int> remindUnread(int id);
}
