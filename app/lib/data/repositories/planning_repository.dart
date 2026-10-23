import '../../models/planning.dart';

abstract class PlanningRepository {
  Future<PlanningWeek> week(DateTime day);
  Future<void> setServiceSize(int eventId, int size);

  /// [member] null clears the slot. [force] confirms a double-service warning.
  /// Throws ApiException code `double_service` (409), `on_leave`.
  Future<void> setSlot(
    int serviceId,
    Slot slot,
    int? member, {
    bool force = false,
  });
  Future<List<Candidate>> candidates(int serviceId);
  Future<List<ServiceGroupInfo>> groups();
  Future<(int, int)> assignGroup(int serviceId, int groupId);

  /// Designates the service's chef de groupe among its guards (null removes).
  Future<void> setChef(int serviceId, int? member);
  Future<int> publish(DateTime day);
  Future<List<DutyAssignment>> mine();
  Future<void> confirm(int assignmentId);
  Future<List<Candidate>> swapCandidates(int assignmentId);
  Future<void> requestSwap(
    int assignmentId, {
    required int target,
    String reason = '',
  });
  Future<void> declareAbsence(int assignmentId, {String reason = ''});

  /// (for me, to decide)
  Future<(List<DutyRequest>, List<DutyRequest>)> requests();
  Future<void> answer(int requestId, {required bool accept});
  Future<void> decide(int requestId, {required bool approve, int? replacement});
  Future<List<Candidate>> replacementCandidates(int requestId);
  Future<AlbOverview> albs();
  Future<void> scheduleAlbs(DateTime weekStart, {int? groupId});
  Future<void> advanceAlbs(int id);
}

abstract class NotificationsRepository {
  Future<(int, List<AppNotification>)> list();
  Future<void> markRead({List<int>? ids});
}
