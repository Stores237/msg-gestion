import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Stockage et données" (owner, 2026-10-28, after the phone's own
/// Storage and data screen): what the app downloads on its own, the quality
/// of photos it sends, and how much data it has used. Kept on this phone.
class DataSettings extends ChangeNotifier {
  DataSettings();

  static DataSettings instance = DataSettings();

  @visibleForTesting
  static void debugSetInstance(DataSettings s) => instance = s;

  static const _saverKey = 'data_saver';
  static const _qualityKey = 'upload_quality';
  static const _mobileKey = 'auto_photos_mobile';
  static const _wifiKey = 'auto_photos_wifi';
  static const _sentKey = 'bytes_sent';
  static const _receivedKey = 'bytes_received';
  static const _sinceKey = 'bytes_since';

  /// Less data on mobile data: no automatic photos, photos sent in
  /// standard quality.
  bool dataSaver = false;

  /// standard | high
  String uploadQuality = 'standard';

  /// Member photos load by themselves on mobile data / on Wi-Fi.
  bool autoPhotosMobile = true;
  bool autoPhotosWifi = true;

  /// What the app sent and received through its API (since [since]).
  int bytesSent = 0;
  int bytesReceived = 0;
  DateTime? since;

  /// wifi | mobile | none | unknown (tests, or before the first answer).
  String network = 'unknown';

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      dataSaver = p.getBool(_saverKey) ?? false;
      uploadQuality = p.getString(_qualityKey) ?? 'standard';
      autoPhotosMobile = p.getBool(_mobileKey) ?? true;
      autoPhotosWifi = p.getBool(_wifiKey) ?? true;
      bytesSent = p.getInt(_sentKey) ?? 0;
      bytesReceived = p.getInt(_receivedKey) ?? 0;
      final s = p.getString(_sinceKey);
      since = s == null ? null : DateTime.tryParse(s);
    } catch (_) {
      // No storage: the defaults.
    }
    try {
      _apply(await Connectivity().checkConnectivity());
      _sub = Connectivity().onConnectivityChanged.listen(_apply);
    } catch (_) {
      // No plugin (tests): unknown network, photos load as usual.
    }
    notifyListeners();
  }

  void _apply(List<ConnectivityResult> r) {
    final next =
        r.contains(ConnectivityResult.wifi) ||
            r.contains(ConnectivityResult.ethernet)
        ? 'wifi'
        : r.contains(ConnectivityResult.mobile)
        ? 'mobile'
        : r.contains(ConnectivityResult.none)
        ? 'none'
        : 'unknown';
    if (next != network) {
      network = next;
      notifyListeners();
    }
  }

  /// Whether member photos load by themselves on the current network.
  bool get autoPhotos => switch (network) {
    'mobile' => autoPhotosMobile && !dataSaver,
    'wifi' => autoPhotosWifi,
    _ => true,
  };

  /// Photo sending: (max side in px, JPEG quality). Standard keeps a photo
  /// around 150 KB; high around 600 KB.
  (double, int) get uploadSize =>
      uploadQuality == 'high' && !(dataSaver && network == 'mobile')
      ? (2048, 92)
      : (1024, 85);

  Future<void> _set(void Function(SharedPreferences p) write) async {
    notifyListeners();
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  Future<void> setDataSaver(bool v) {
    dataSaver = v;
    return _set((p) => p.setBool(_saverKey, v));
  }

  Future<void> setUploadQuality(String v) {
    uploadQuality = v;
    return _set((p) => p.setString(_qualityKey, v));
  }

  Future<void> setAutoPhotos({bool? mobile, bool? wifi}) {
    autoPhotosMobile = mobile ?? autoPhotosMobile;
    autoPhotosWifi = wifi ?? autoPhotosWifi;
    return _set((p) {
      p.setBool(_mobileKey, autoPhotosMobile);
      p.setBool(_wifiKey, autoPhotosWifi);
    });
  }

  /// Counted by ApiClient for every request and answer.
  void countTraffic({int sent = 0, int received = 0}) {
    bytesSent += sent;
    bytesReceived += received;
    since ??= DateTime.now();
    // A few bytes in the phone's preferences: written as it goes, no timer.
    unawaited(_persistCounters());
  }

  Future<void> _persistCounters() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_sentKey, bytesSent);
      await p.setInt(_receivedKey, bytesReceived);
      if (since != null) await p.setString(_sinceKey, since!.toIso8601String());
    } catch (_) {}
  }

  Future<void> resetTraffic() {
    bytesSent = 0;
    bytesReceived = 0;
    since = DateTime.now();
    return _set((p) {
      p.setInt(_sentKey, 0);
      p.setInt(_receivedKey, 0);
      p.setString(_sinceKey, since!.toIso8601String());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
