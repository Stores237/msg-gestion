import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../data/data_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'ui.dart';

/// Photos in announcements (owner, 2026-10-28): one frame for all, a size
/// cap, a few per announcement. The server checks the same rules
/// (backend/apps/announcements/files.py).
const photoRatio = 4 / 3; // landscape
const photoMaxBytes = 2 * 1024 * 1024;
const photosPerAnnouncement = 4;

/// A framed photo ready to send.
class FramedPhoto {
  const FramedPhoto(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Picks a raw photo; replaced in tests (no camera or gallery there).
Future<Uint8List?> Function(ImageSource) pickRawPhoto = (source) async {
  // Re-encoded by the picker, so the phone's rotation is already applied.
  final f = await ImagePicker().pickImage(
    source: source,
    maxWidth: 4096,
    maxHeight: 4096,
    imageQuality: 95,
  );
  return f?.readAsBytes();
};

/// Gallery or camera, then the framing screen. Null when cancelled.
Future<FramedPhoto?> addFramedPhoto(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('photo-src-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.photoFromGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            key: const Key('photo-src-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.photoFromCamera),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final raw = await pickRawPhoto(source);
  if (raw == null || !context.mounted) return null;
  return Navigator.of(context).push<FramedPhoto>(
    MaterialPageRoute(builder: (_) => FramePhotoScreen(bytes: raw)),
  );
}

/// The crop (in the source image's pixels) and the output size.
typedef FrameJob = (Uint8List bytes, Rect crop, int width, int height);

/// Crops [job] to its rectangle, resizes to the target and encodes JPEG,
/// lowering the quality until it fits [photoMaxBytes]. Pure, so it runs in
/// an isolate (compute) and in tests.
Uint8List framePhoto(FrameJob job) {
  final (bytes, crop, width, height) = job;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('image');
  final src = img.bakeOrientation(decoded);
  final x = crop.left.round().clamp(0, src.width - 1);
  final y = crop.top.round().clamp(0, src.height - 1);
  final w = crop.width.round().clamp(1, src.width - x);
  final h = crop.height.round().clamp(1, src.height - y);
  final cut = img.copyCrop(src, x: x, y: y, width: w, height: h);
  final out = img.copyResize(
    cut,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
  for (final q in [85, 75, 65, 55, 45]) {
    final jpg = img.encodeJpg(out, quality: q);
    if (jpg.length <= photoMaxBytes) return jpg;
  }
  return img.encodeJpg(out, quality: 35);
}

/// "Cadrer la photo": the picture under a fixed 4:3 frame; move and zoom
/// it, what's inside the frame is kept (design-system cards and buttons).
class FramePhotoScreen extends StatefulWidget {
  const FramePhotoScreen({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<FramePhotoScreen> createState() => _FramePhotoScreenState();
}

class _FramePhotoScreenState extends State<FramePhotoScreen> {
  final _transform = TransformationController();
  Size? _image; // source pixels
  Size? _frame; // frame size on screen
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    decodeImageFromList(widget.bytes)
        .then((im) {
          if (!mounted) return;
          setState(
            () => _image = Size(im.width.toDouble(), im.height.toDouble()),
          );
          im.dispose();
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// The picture as laid out under the frame: covering it, centred.
  (double scale, Size shown) _cover(Size frame, Size image) {
    final s = [
      frame.width / image.width,
      frame.height / image.height,
    ].reduce((a, b) => a > b ? a : b);
    return (s, Size(image.width * s, image.height * s));
  }

  void _center(Size frame, Size image) {
    final (_, shown) = _cover(frame, image);
    _transform.value = Matrix4.translationValues(
      -(shown.width - frame.width) / 2,
      -(shown.height - frame.height) / 2,
      0,
    );
  }

  Future<void> _use() async {
    final frame = _frame, image = _image;
    if (frame == null || image == null) return;
    setState(() => _busy = true);
    final (cover, _) = _cover(frame, image);
    final m = _transform.value;
    final zoom = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    // The frame's corners in the shown picture, then in source pixels.
    final crop = Rect.fromLTWH(
      -t.x / zoom / cover,
      -t.y / zoom / cover,
      frame.width / zoom / cover,
      frame.height / zoom / cover,
    );
    final (side, _) = DataSettings.instance.uploadSize;
    final width = side.round().clamp(320, 2048);
    final height = (width / photoRatio).round();
    try {
      final out = await compute(framePhoto, (
        widget.bytes,
        crop,
        width,
        height,
      ));
      if (!mounted) return;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      Navigator.of(context).pop(FramedPhoto('photo-$stamp.jpg', out));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final image = _image;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.framePhoto, back: true, small: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l.framePhotoHint,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: photoRatio,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final frame = box.biggest;
                        if (image == null) {
                          return Center(
                            child: _error == null
                                ? const CircularProgressIndicator()
                                : Text(l.photoUnreadable),
                          );
                        }
                        final (_, shown) = _cover(frame, image);
                        if (_frame != frame) {
                          _frame = frame;
                          _center(frame, image);
                        }
                        return DecoratedBox(
                          key: const Key('photo-frame'),
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            border: Border.all(color: c.primary, width: 3),
                            borderRadius: BorderRadius.circular(MsgRadius.md),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(MsgRadius.md),
                            child: InteractiveViewer(
                              transformationController: _transform,
                              constrained: false,
                              minScale: 1,
                              maxScale: 4,
                              child: SizedBox.fromSize(
                                size: shown,
                                child: Image.memory(
                                  widget.bytes,
                                  fit: BoxFit.fill,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l.photoRules,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('photo-use'),
                  onPressed: _busy || image == null ? null : _use,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.usePhoto),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A photo of an announcement in its 4:3 frame. Follows Mon compte →
/// Stockage et données: when photos don't load by themselves on this
/// network, a tap loads it. A tap on a loaded photo opens it full screen.
class AnnouncementPhoto extends StatefulWidget {
  const AnnouncementPhoto({super.key, required this.url, this.badge});
  final String url;

  /// "+2" on the first photo of a card when there are more.
  final String? badge;

  @override
  State<AnnouncementPhoto> createState() => _AnnouncementPhotoState();
}

class _AnnouncementPhotoState extends State<AnnouncementPhoto> {
  bool _asked = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final show = _asked || DataSettings.instance.autoPhotos;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MsgRadius.md),
      child: AspectRatio(
        aspectRatio: photoRatio,
        child: Material(
          color: c.surfaceSunken,
          child: InkWell(
            onTap: show
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PhotoViewer(url: widget.url),
                    ),
                  )
                : () => setState(() => _asked = true),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (show)
                  Image.network(
                    widget.url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: c.textTertiary,
                    ),
                  )
                else
                  Column(
                    key: const Key('photo-tap-to-load'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_outlined, color: c.textSecondary),
                      const SizedBox(height: 4),
                      Text(
                        l.showPhoto,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ],
                  ),
                if (widget.badge != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: InteractiveViewer(maxScale: 5, child: Image.network(url)),
    ),
  );
}
