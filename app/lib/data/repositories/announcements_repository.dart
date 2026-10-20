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
}
