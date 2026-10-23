import '../../../models/planning.dart';
import '../../api_client.dart';
import '../../offline.dart';
import '../planning_repository.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<Candidate> _cands(Object? data) => [
  for (final c in data as List) Candidate.fromJson(c as Map<String, dynamic>),
];

class HttpPlanningRepository implements PlanningRepository {
  HttpPlanningRepository(this._api);
  final ApiClient _api;

  @override
  Future<PlanningWeek> week(DateTime day) async => PlanningWeek.fromJson(
    await _api.get('/planning/week/', query: {'day': _day(day)})
        as Map<String, dynamic>,
  );

  @override
  Future<void> setServiceSize(int eventId, int size) =>
      _api.post('/planning/services/', body: {'event': eventId, 'size': size});

  @override
  Future<void> setSlot(
    int serviceId,
    Slot slot,
    int? member, {
    bool force = false,
  }) => _api.put(
    '/planning/services/$serviceId/slot/',
    body: {
      'post': slot.post,
      'side': slot.side,
      'index': slot.index,
      'member': member,
      'force': force,
    },
  );

  @override
  Future<List<Candidate>> candidates(int serviceId) async =>
      _cands(await _api.get('/planning/services/$serviceId/candidates/'));

  @override
  Future<List<ServiceGroupInfo>> groups() async => [
    for (final g in await _api.get('/planning/groups/') as List)
      ServiceGroupInfo.fromJson(g as Map<String, dynamic>),
  ];

  @override
  Future<(int, int)> assignGroup(int serviceId, int groupId) async {
    final j =
        await _api.post(
              '/planning/services/$serviceId/assign-group/',
              body: {'group': groupId},
            )
            as Map<String, dynamic>;
    return (j['assigned'] as int, j['still_empty'] as int);
  }

  @override
  Future<void> setChef(int serviceId, int? member) =>
      _api.put('/planning/services/$serviceId/chef/', body: {'member': member});

  @override
  Future<int> publish(DateTime day) async =>
      ((await _api.post('/planning/publish/', body: {'day': _day(day)}))
              as Map<String, dynamic>)['notified']
          as int;

  @override
  Future<List<DutyAssignment>> mine() async => [
    for (final a in await _api.get('/planning/mine/') as List)
      DutyAssignment.fromJson(a as Map<String, dynamic>),
  ];

  @override
  Future<void> confirm(int assignmentId) => _api.sendOrQueue(
    'POST',
    '/planning/assignments/$assignmentId/confirm/',
    kind: 'confirm',
  );

  @override
  Future<List<Candidate>> swapCandidates(int assignmentId) async => _cands(
    await _api.get('/planning/assignments/$assignmentId/swap-candidates/'),
  );

  @override
  Future<void> requestSwap(
    int assignmentId, {
    required int target,
    String reason = '',
  }) => _api.post(
    '/planning/assignments/$assignmentId/swap/',
    body: {'target': target, 'reason': reason},
  );

  @override
  Future<void> declareAbsence(int assignmentId, {String reason = ''}) =>
      _api.post(
        '/planning/assignments/$assignmentId/swap/',
        body: {'absence': true, 'reason': reason},
      );

  @override
  Future<(List<DutyRequest>, List<DutyRequest>)> requests() async {
    final j = await _api.get('/planning/requests/') as Map<String, dynamic>;
    List<DutyRequest> parse(String k) => [
      for (final r in j[k] as List)
        DutyRequest.fromJson(r as Map<String, dynamic>),
    ];
    return (parse('for_me'), parse('to_decide'));
  }

  @override
  Future<void> answer(int requestId, {required bool accept}) => _api.post(
    '/planning/requests/$requestId/answer/',
    body: {'accept': accept},
  );

  @override
  Future<void> decide(
    int requestId, {
    required bool approve,
    int? replacement,
  }) => _api.post(
    '/planning/requests/$requestId/decide/',
    body: {'approve': approve, 'replacement': replacement},
  );

  @override
  Future<List<Candidate>> replacementCandidates(int requestId) async =>
      _cands(await _api.get('/planning/requests/$requestId/candidates/'));

  @override
  Future<AlbOverview> albs() async {
    final j = await _api.get('/planning/albs/') as Map<String, dynamic>;
    return AlbOverview(
      weeks: [
        for (final w in j['weeks'] as List)
          AlbWeek.fromJson(w as Map<String, dynamic>),
      ],
      fairness: [
        for (final f in j['fairness'] as List)
          (f['name'] as String, f['count'] as int),
      ],
    );
  }

  @override
  Future<void> scheduleAlbs(DateTime weekStart, {int? groupId}) => _api.post(
    '/planning/albs/',
    body: {'week_start': _day(weekStart), 'group': groupId},
  );

  @override
  Future<void> advanceAlbs(int id) => _api.post('/planning/albs/$id/advance/');
}

class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._api);
  final ApiClient _api;

  @override
  Future<(int, List<AppNotification>)> list() async {
    final j = await _api.get('/notifications/') as Map<String, dynamic>;
    return (
      j['unread'] as int,
      [
        for (final n in j['results'] as List)
          AppNotification.fromJson(n as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<void> markRead({List<int>? ids}) async {
    try {
      await _api.sendOrQueue(
        'POST',
        '/notifications/read/',
        body: {'ids': ?ids},
        kind: 'notifications',
      );
    } on QueuedOffline {
      // Sent later.
    }
  }
}
