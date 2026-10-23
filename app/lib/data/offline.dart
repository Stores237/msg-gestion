import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Where offline data lives. Files in the app's private directory by
/// default; memory in tests.
abstract class OfflineStorage {
  Future<String?> read(String name);
  Future<void> write(String name, String data);
}

class FileOfflineStorage implements OfflineStorage {
  Future<File> _file(String name) async =>
      File('${(await getApplicationSupportDirectory()).path}/$name');

  @override
  Future<String?> read(String name) async {
    try {
      final f = await _file(name);
      return await f.exists() ? await f.readAsString() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String name, String data) async {
    try {
      await (await _file(name)).writeAsString(data, flush: true);
    } catch (_) {
      // Disk full or unavailable: the app keeps working online.
    }
  }
}

class MemoryOfflineStorage implements OfflineStorage {
  final data = <String, String>{};

  @override
  Future<String?> read(String name) async => data[name];

  @override
  Future<void> write(String name, String d) async => data[name] = d;
}

/// A write made without network, sent later. Only idempotent operations
/// are queued (the server de-duplicates entries by client_uuid; roll call,
/// absence notice, confirm and "read" are idempotent by nature).
class OutboxItem {
  OutboxItem({
    required this.method,
    required this.path,
    this.body,
    required this.kind,
    this.groupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String method;
  final String path;
  final Object? body;

  /// entry | attendance | excuse | read | confirm | notifications
  final String kind;

  /// The group it was made in: sent there even if the member switched
  /// group before the network came back.
  final int? groupId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'method': method,
    'path': path,
    'body': body,
    'kind': kind,
    'group': groupId,
    'created_at': createdAt.toIso8601String(),
  };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    method: j['method'] as String,
    path: j['path'] as String,
    body: j['body'],
    kind: j['kind'] as String,
    groupId: j['group'] as int?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

/// Thrown after a write was queued instead of sent: the caller shows
/// "Enregistré sur le téléphone" and carries on.
class QueuedOffline implements Exception {
  const QueuedOffline(this.item);
  final OutboxItem item;
}

/// Read cache + outbox + what the sync line shows.
class OfflineState extends ChangeNotifier {
  OfflineState({OfflineStorage? storage})
    : _storage = storage ?? FileOfflineStorage();

  static OfflineState instance = OfflineState();

  @visibleForTesting
  static void debugSetInstance(OfflineState s) => instance = s;

  final OfflineStorage _storage;
  static const _cacheFile = 'msg_cache.json';
  static const _outboxFile = 'msg_outbox.json';

  Map<String, dynamic> _cache = {};
  List<OutboxItem> _outbox = [];
  bool _loaded = false;

  bool online = true;
  bool syncing = false;
  DateTime? lastSync;

  /// Last send failure the server refused (not a network problem).
  String? lastError;

  List<OutboxItem> get outbox => List.unmodifiable(_outbox);
  int get pending => _outbox.length;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final c = await _storage.read(_cacheFile);
      if (c != null) _cache = jsonDecode(c) as Map<String, dynamic>;
      final o = await _storage.read(_outboxFile);
      if (o != null) {
        _outbox = [
          for (final i in jsonDecode(o) as List)
            OutboxItem.fromJson(i as Map<String, dynamic>),
        ];
      }
      final ls = _cache['__last_sync'] as String?;
      if (ls != null) lastSync = DateTime.parse(ls);
    } catch (_) {
      _cache = {};
      _outbox = [];
    }
    notifyListeners();
  }

  // --- read cache ---------------------------------------------------------

  Future<void> remember(String key, Object? data) async {
    _cache[key] = data;
    lastSync = DateTime.now();
    _cache['__last_sync'] = lastSync!.toIso8601String();
    if (!online) {
      online = true;
      notifyListeners();
    }
    await _storage.write(_cacheFile, jsonEncode(_cache));
  }

  bool has(String key) => _cache.containsKey(key);
  Object? recall(String key) => _cache[key];

  void markOffline() {
    if (online) {
      online = false;
      notifyListeners();
    }
  }

  void markOnline() {
    lastSync = DateTime.now();
    if (!online) {
      online = true;
      notifyListeners();
    }
  }

  // --- outbox -----------------------------------------------------------------

  Future<void> enqueue(OutboxItem item) async {
    _outbox.add(item);
    markOffline();
    notifyListeners();
    await _saveOutbox();
  }

  Future<void> _saveOutbox() => _storage.write(
    _outboxFile,
    jsonEncode([for (final i in _outbox) i.toJson()]),
  );

  /// Send queued writes in order. [send] performs one request; it throws
  /// a network error (stop, keep the rest) or an HTTP error (drop that
  /// item and remember why).
  Future<void> flush(
    Future<void> Function(OutboxItem) send, {
    required bool Function(Object) isNetworkError,
  }) async {
    if (syncing || _outbox.isEmpty) return;
    syncing = true;
    notifyListeners();
    try {
      while (_outbox.isNotEmpty) {
        final item = _outbox.first;
        try {
          await send(item);
        } catch (e) {
          if (isNetworkError(e)) {
            markOffline();
            return;
          }
          lastError = e.toString();
        }
        _outbox.removeAt(0);
        await _saveOutbox();
        notifyListeners();
      }
      markOnline();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
