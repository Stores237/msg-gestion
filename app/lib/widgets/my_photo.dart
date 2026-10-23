import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/current_user.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import 'errors.dart';

/// Photo de profil: every member picks, takes or removes their own picture
/// (owner, 2026-10-23). The new picture shows at once wherever the member's
/// avatar is drawn from [currentUser].
Future<void> changeMyPhoto(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final hasPhoto = currentUser.value?.photo != null;
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l.myPhoto,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            key: const Key('photo-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.photoFromGallery),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            key: const Key('photo-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.photoFromCamera),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          if (hasPhoto)
            ListTile(
              key: const Key('photo-remove'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l.removePhoto),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final repo = RepositoryLocator.instance.profile;
  try {
    if (choice == 'remove') {
      await repo.removeMyPhoto();
      currentUser.value = currentUser.value?.withPhoto(null);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.photoRemoved)));
      }
      return;
    }
    final picked = await pickPhoto(
      choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null || !context.mounted) return;
    final url = await repo.uploadMyPhoto(bytes: picked.$1, filename: picked.$2);
    currentUser.value = currentUser.value?.withPhoto(url);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.photoSaved)));
    }
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}

/// Square-ish, ≤ 1024 px, JPEG quality 85: well under the server's 5 MB.
/// Replaced in tests (no camera or gallery there).
Future<(List<int>, String)?> Function(ImageSource) pickPhoto = (source) async {
  final f = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.front,
  );
  return f == null ? null : (await f.readAsBytes(), f.name);
};
