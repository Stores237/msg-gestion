import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'data_settings.dart';

/// Photos and files kept on the phone (owner, 2026-10-29): what was seen
/// stays viewable without network, and a photo or PDF can be downloaded.
///
/// Two places, both in the app's private directory:
/// - `media/`: every photo shown (announcements, member photos), keyed by
///   the file's address without its signature, so a fresh signed link
///   finds the copy. Trimmed to [mediaMaxBytes], oldest first.
/// - `downloads/`: files the member downloaded or opened (photos, PDF
///   reports, attachments), listed in Mon compte → Téléchargements and kept
///   until deleted there. A download is also copied to the phone's own
///   Pictures/MSG or Download/MSG (Android), outside the app.
/// Both are erased with the offline data (sign-out, another member).
class FileStore extends ChangeNotifier {
  FileStore({FileBackend? backend, Fetcher? fetch, FilePlatform? platform})
    : _backend = backend ?? DiskFileBackend(),
      _fetch = fetch ?? _httpFetch,
      platform = platform ?? const ChannelFilePlatform();

  static FileStore instance = FileStore();

  @visibleForTesting
  static void debugSetInstance(FileStore s) => instance = s;

  static const mediaMaxBytes = 150 * 1024 * 1024;
  static const _index = 'downloads/index.json';

  final FileBackend _backend;
  final Fetcher _fetch;
  final FilePlatform platform;

  /// media key → (size, last used).
  final _media = <String, (int, DateTime)>{};
  final _downloads = <DownloadedFile>[];
  final _inFlight = <String, Future<Uint8List>>{};
  Future<void>? _loading;

  List<DownloadedFile> get downloads => List.unmodifiable(_downloads);
  int get mediaBytes => _media.values.fold(0, (s, e) => s + e.$1);
  int get downloadBytes => _downloads.fold(0, (s, e) => s + e.size);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      for (final (name, size, modified) in await _backend.list('media')) {
        _media[name] = (size, modified);
      }
      final raw = await _backend.read(_index);
      if (raw != null) {
        _downloads.addAll([
          for (final j in jsonDecode(utf8.decode(raw)) as List)
            DownloadedFile.fromJson(j as Map<String, dynamic>),
        ]);
      }
    } catch (_) {
      // Unreadable: starts empty, the server still has everything.
    }
    notifyListeners();
  }

  /// The address without its signature: `…/announcements/a1b2.jpg?X-Amz-…`
  /// and the next signed link to the same file share one copy.
  static String keyFor(String url) {
    final u = Uri.parse(url);
    final ext = RegExp(r'\.[A-Za-z0-9]{1,5}$').stringMatch(u.path) ?? '';
    return '${sha1.convert(utf8.encode('${u.host}${u.path}'))}$ext';
  }

  bool isCached(String url) => _media.containsKey(keyFor(url));

  /// The photo or file at [url]: the copy on the phone, otherwise
  /// downloaded and kept in `media/` (unless not [remember]: a PDF goes
  /// to Téléchargements instead). Throws without network and without a copy.
  Future<Uint8List> bytes(String url, {bool remember = true}) async {
    await load();
    final key = keyFor(url);
    if (_media.containsKey(key)) {
      final kept = await _backend.read('media/$key');
      if (kept != null) {
        _media[key] = (kept.length, DateTime.now());
        return kept;
      }
      _media.remove(key);
    }
    if (!remember) {
      final data = await _fetch(Uri.parse(url));
      DataSettings.instance.countTraffic(received: data.length);
      return data;
    }
    // A block body: returning the removed future would wait on itself.
    return _inFlight[key] ??= _download(key, url).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<Uint8List> _download(String key, String url) async {
    final data = await _fetch(Uri.parse(url));
    DataSettings.instance.countTraffic(received: data.length);
    await _backend.write('media/$key', data);
    _media[key] = (data.length, DateTime.now());
    await _trim();
    notifyListeners();
    return data;
  }

  Future<void> _trim() async {
    var total = mediaBytes;
    if (total <= mediaMaxBytes) return;
    final oldest = _media.entries.toList()
      ..sort((a, b) => a.value.$2.compareTo(b.value.$2));
    for (final e in oldest) {
      if (total <= mediaMaxBytes) break;
      await _backend.delete('media/${e.key}');
      _media.remove(e.key);
      total -= e.value.$1;
    }
  }

  Future<void> clearMedia() async {
    for (final k in _media.keys.toList()) {
      await _backend.delete('media/$k');
    }
    _media.clear();
    notifyListeners();
  }

  // --- downloads ------------------------------------------------------------

  /// The kept copy of [source] (e.g. `att-12`, `fin-report-2026-3`), to
  /// open without network.
  DownloadedFile? bySource(String source) {
    for (final d in _downloads) {
      if (d.source == source) return d;
    }
    return null;
  }

  /// Keeps [url] (or [data]) in Téléchargements under [name]. The same
  /// [source] downloaded again replaces its copy.
  Future<DownloadedFile> keep({
    required String source,
    required String name,
    required String mime,
    String? url,
    Uint8List? data,
  }) async {
    await load();
    final bytes =
        data ?? await this.bytes(url!, remember: !mime.endsWith('pdf'));
    final digest = sha1.convert(bytes).toString();
    final old = bySource(source);
    if (old != null && old.sha == digest) {
      // Unchanged: same file, same "on the phone" state, newer date.
      final same = old.copyWith(savedAt: DateTime.now());
      _downloads[_downloads.indexOf(old)] = same;
      await _saveIndex();
      return same;
    }
    if (old != null) await _remove(old);
    final ext = RegExp(r'\.[A-Za-z0-9]{1,5}$').stringMatch(name) ?? '';
    final file = DownloadedFile(
      source: source,
      name: name,
      mime: mime,
      size: bytes.length,
      sha: digest,
      path: 'downloads/${digest.substring(0, 16)}$ext',
      savedAt: DateTime.now(),
    );
    await _backend.write(file.path, bytes);
    _downloads.insert(0, file);
    await _saveIndex();
    notifyListeners();
    return file;
  }

  /// Copies [file] to the phone's Pictures/MSG (photos) or Download/MSG,
  /// once. False when the phone refused (or isn't Android).
  Future<bool> saveToPhone(DownloadedFile file) async {
    if (file.onPhone) return true;
    final path = await _backend.localPath(file.path);
    if (path == null) return false;
    final ok = await platform.saveToPhone(path, file.name, file.mime);
    if (ok) {
      final i = _downloads.indexWhere((d) => d.path == file.path);
      if (i >= 0) _downloads[i] = _downloads[i].copyWith(onPhone: true);
      await _saveIndex();
      notifyListeners();
    }
    return ok;
  }

  /// Opens a kept PDF in the phone's viewer. False if none is installed.
  Future<bool> openFile(DownloadedFile file) async {
    final path = await _backend.localPath(file.path);
    return path != null && await platform.open(path, file.mime);
  }

  Future<Uint8List?> read(DownloadedFile file) => _backend.read(file.path);

  Future<void> delete(DownloadedFile file) async {
    await _remove(file);
    await _saveIndex();
    notifyListeners();
  }

  Future<void> _remove(DownloadedFile file) async {
    _downloads.removeWhere((d) => d.path == file.path);
    // Another source may hold the very same file.
    if (!_downloads.any((d) => d.path == file.path)) {
      await _backend.delete(file.path);
    }
  }

  Future<void> _saveIndex() => _backend.write(
    _index,
    utf8.encode(jsonEncode([for (final d in _downloads) d.toJson()])),
  );

  /// Everything goes: sign-out, too many wrong PINs, another member.
  /// Copies already in the phone's Pictures or Download folder stay: the
  /// member put them there.
  Future<void> forget() async {
    await load();
    await clearMedia();
    for (final d in _downloads.toList()) {
      await _backend.delete(d.path);
    }
    _downloads.clear();
    await _saveIndex();
    notifyListeners();
  }
}

class DownloadedFile {
  const DownloadedFile({
    required this.source,
    required this.name,
    required this.mime,
    required this.size,
    required this.sha,
    required this.path,
    required this.savedAt,
    this.onPhone = false,
  });

  final String source;
  final String name;
  final String mime;
  final int size;
  final String sha;
  final String path;
  final DateTime savedAt;

  /// Also copied to the phone's Pictures/MSG or Download/MSG.
  final bool onPhone;

  bool get isImage => mime.startsWith('image/');
  bool get isPdf => mime == 'application/pdf';

  DownloadedFile copyWith({DateTime? savedAt, bool? onPhone}) => DownloadedFile(
    source: source,
    name: name,
    mime: mime,
    size: size,
    sha: sha,
    path: path,
    savedAt: savedAt ?? this.savedAt,
    onPhone: onPhone ?? this.onPhone,
  );

  Map<String, dynamic> toJson() => {
    'source': source,
    'name': name,
    'mime': mime,
    'size': size,
    'sha': sha,
    'path': path,
    'saved_at': savedAt.toIso8601String(),
    'on_phone': onPhone,
  };

  factory DownloadedFile.fromJson(Map<String, dynamic> j) => DownloadedFile(
    source: j['source'] as String,
    name: j['name'] as String,
    mime: j['mime'] as String,
    size: j['size'] as int,
    sha: j['sha'] as String,
    path: j['path'] as String,
    savedAt: DateTime.parse(j['saved_at'] as String),
    onPhone: (j['on_phone'] as bool?) ?? false,
  );
}

/// Downloads a file (signed link: no app token).
typedef Fetcher = Future<Uint8List> Function(Uri url);

/// No answer at all: offline, DNS, timeout.
class FileUnavailable implements Exception {
  const FileUnavailable(this.cause);
  final Object cause;

  @override
  String toString() => 'FileUnavailable($cause)';
}

Future<Uint8List> _httpFetch(Uri url) async {
  final http.Response r;
  try {
    r = await http.get(url).timeout(const Duration(seconds: 60));
  } on SocketException catch (e) {
    throw FileUnavailable(e);
  } on TimeoutException catch (e) {
    throw FileUnavailable(e);
  } on http.ClientException catch (e) {
    throw FileUnavailable(e);
  }
  if (r.statusCode != 200) throw HttpException('HTTP ${r.statusCode}');
  return r.bodyBytes;
}

/// Where the bytes live: the app's private directory, or memory in tests.
abstract class FileBackend {
  Future<Uint8List?> read(String path);
  Future<void> write(String path, Uint8List data);
  Future<void> delete(String path);

  /// (name, size, modified) of the files in [dir].
  Future<List<(String, int, DateTime)>> list(String dir);

  /// A real file path for the phone's viewer; null in memory.
  Future<String?> localPath(String path);
}

class DiskFileBackend implements FileBackend {
  Future<File> _file(String path) async =>
      File('${(await getApplicationSupportDirectory()).path}/msg_files/$path');

  @override
  Future<Uint8List?> read(String path) async {
    try {
      final f = await _file(path);
      return await f.exists() ? await f.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String path, Uint8List data) async {
    try {
      final f = await _file(path);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(data, flush: true);
    } catch (_) {
      // Disk full: shown from the network, not kept.
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      final f = await _file(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  Future<List<(String, int, DateTime)>> list(String dir) async {
    final d = Directory(
      '${(await getApplicationSupportDirectory()).path}/msg_files/$dir',
    );
    if (!await d.exists()) return [];
    return [
      await for (final e in d.list())
        if (e is File)
          (e.uri.pathSegments.last, await e.length(), await e.lastModified()),
    ];
  }

  @override
  Future<String?> localPath(String path) async => (await _file(path)).path;
}

class MemoryFileBackend implements FileBackend {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String path) async => files[path];

  @override
  Future<void> write(String path, Uint8List data) async => files[path] = data;

  @override
  Future<void> delete(String path) async => files.remove(path);

  @override
  Future<List<(String, int, DateTime)>> list(String dir) async => [
    for (final e in files.entries)
      if (e.key.startsWith('$dir/'))
        (e.key.substring(dir.length + 1), e.value.length, DateTime.now()),
  ];

  @override
  Future<String?> localPath(String path) async =>
      files.containsKey(path) ? '/memory/$path' : null;
}

/// What only the phone can do: put a copy in its Pictures / Download
/// folder, open a PDF in its viewer. MainActivity.kt (channel `msg/files`).
abstract class FilePlatform {
  Future<bool> saveToPhone(String path, String name, String mime);
  Future<bool> open(String path, String mime);
}

class ChannelFilePlatform implements FilePlatform {
  const ChannelFilePlatform();
  static const _channel = MethodChannel('msg/files');

  Future<bool> _call(String method, Map<String, String> args) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on MissingPluginException {
      return false; // iOS for now: the copy stays in the app.
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> saveToPhone(String path, String name, String mime) =>
      _call('save', {'path': path, 'name': name, 'mime': mime});

  @override
  Future<bool> open(String path, String mime) =>
      _call('open', {'path': path, 'mime': mime});
}
