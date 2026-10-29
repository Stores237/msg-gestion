import 'package:flutter/material.dart';

import '../data/data_settings.dart';
import '../data/file_store.dart';
import '../data/offline.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/ui.dart';
import 'downloads_screen.dart';

/// "Stockage et données" (owner, 2026-10-28, after the phone's own Storage
/// and data screen): what the app keeps on the phone, the data it has used,
/// photo quality and what loads by itself on each network. Only what
/// applies to MSG: no proxy (a phone setting), no roaming (not detectable).
class StorageDataScreen extends StatelessWidget {
  const StorageDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = DataSettings.instance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.storageAndData, back: true, small: true),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  settings,
                  OfflineState.instance,
                  FileStore.instance,
                ]),
                builder: (context, _) => _Body(settings: settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 234 octets → "2 Ko" / "1,2 Mo" / "1,1 Go".
String bytesLabel(AppLocalizations l, int bytes) {
  if (bytes < 1024 * 1024) return l.sizeKb((bytes / 1024).ceil());
  if (bytes < 1024 * 1024 * 1024) {
    return l.sizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
  }
  return l.sizeGb((bytes / (1024 * 1024 * 1024)).toStringAsFixed(1));
}

class _Body extends StatelessWidget {
  const _Body({required this.settings});
  final DataSettings settings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final (cached, unsent) = OfflineState.instance.sizes;
    final images = PaintingBinding.instance.imageCache.currentSizeBytes;
    final files = FileStore.instance;
    final kept = files.mediaBytes + files.downloadBytes;
    final saverOnMobile = settings.dataSaver;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GroupCard(
          children: [
            ListRow(
              key: const Key('manage-storage'),
              lead: const Icon(Icons.folder_outlined),
              title: Text(l.manageStorage),
              subtitle: Text(
                l.storageUsed(bytesLabel(l, cached + unsent + images + kept)),
              ),
              chevron: true,
              onTap: () => _manageStorage(context),
            ),
            ListRow(
              key: const Key('storage-downloads'),
              lead: const Icon(Icons.download_outlined),
              title: Text(l.downloads),
              subtitle: Text(bytesLabel(l, files.downloadBytes)),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GroupCard(
          children: [
            ListRow(
              key: const Key('network-usage'),
              lead: const Icon(Icons.data_usage_outlined),
              title: Text(l.networkUsage),
              subtitle: Text(
                [
                  l.trafficSentReceived(
                    bytesLabel(l, settings.bytesSent),
                    bytesLabel(l, settings.bytesReceived),
                  ),
                  if (settings.since != null)
                    l.trafficSince(Dates(context).dayMonth(settings.since!)),
                ].join('\n'),
              ),
              onTap: () => _resetTraffic(context),
            ),
            ListRow(
              title: Text(l.dataSaver),
              subtitle: Text(l.dataSaverHint),
              trailing: Switch(
                key: const Key('data-saver'),
                value: settings.dataSaver,
                onChanged: settings.setDataSaver,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GroupCard(
          children: [
            ListRow(
              key: const Key('upload-quality'),
              lead: const Icon(Icons.high_quality_outlined),
              title: Text(l.uploadQuality),
              subtitle: Text(
                settings.uploadQuality == 'high'
                    ? l.qualityHigh
                    : l.qualityStandard,
              ),
              chevron: true,
              onTap: () => _chooseQuality(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionLabel(l.autoDownload),
        const SizedBox(height: 4),
        Text(
          l.autoDownloadHint,
          style: TextStyle(fontSize: 13, height: 1.4, color: c.textSecondary),
        ),
        const SizedBox(height: 8),
        GroupCard(
          children: [
            ListRow(
              title: Text(l.onMobileData),
              subtitle: Text(
                saverOnMobile
                    ? l.autoOffBySaver
                    : (settings.autoPhotosMobile ? l.memberPhotos : l.noMedia),
              ),
              trailing: Switch(
                key: const Key('auto-mobile'),
                value: settings.autoPhotosMobile && !saverOnMobile,
                onChanged: saverOnMobile
                    ? null
                    : (v) => settings.setAutoPhotos(mobile: v),
              ),
            ),
            ListRow(
              title: Text(l.onWifi),
              subtitle: Text(
                settings.autoPhotosWifi ? l.memberPhotos : l.noMedia,
              ),
              trailing: Switch(
                key: const Key('auto-wifi'),
                value: settings.autoPhotosWifi,
                onChanged: (v) => settings.setAutoPhotos(wifi: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l.currentNetwork(switch (settings.network) {
            'wifi' => l.networkWifi,
            'mobile' => l.networkMobile,
            'none' => l.networkNone,
            _ => l.networkUnknown,
          }),
          key: const Key('current-network'),
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }

  Future<void> _manageStorage(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final (cached, unsent) = OfflineState.instance.sizes;
          final images = PaintingBinding.instance.imageCache.currentSizeBytes;
          Widget clear(Key key, VoidCallback onPressed) =>
              TextButton(key: key, onPressed: onPressed, child: Text(l.clear));
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.manageStorage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GroupCard(
                    children: [
                      ListRow(
                        lead: const Icon(Icons.cloud_download_outlined),
                        title: Text(l.offlineData),
                        subtitle: Text(
                          '${bytesLabel(l, cached)} · ${l.offlineDataHint}',
                        ),
                        trailing: clear(const Key('clear-offline'), () async {
                          await OfflineState.instance.clearCache();
                          setState(() {});
                        }),
                      ),
                      ListRow(
                        lead: const Icon(Icons.outbox_outlined),
                        title: Text(l.unsentChanges),
                        subtitle: Text(
                          '${bytesLabel(l, unsent)} · ${l.unsentKept}',
                        ),
                      ),
                      ListRow(
                        lead: const Icon(Icons.photo_library_outlined),
                        title: Text(l.photosAndFiles),
                        subtitle: Text(
                          '${bytesLabel(l, FileStore.instance.mediaBytes)} · '
                          '${l.photosAndFilesHint}',
                        ),
                        trailing: clear(const Key('clear-media'), () async {
                          await FileStore.instance.clearMedia();
                          setState(() {});
                        }),
                      ),
                      ListRow(
                        lead: const Icon(Icons.image_outlined),
                        title: Text(l.imagesInMemory),
                        subtitle: Text(bytesLabel(l, images)),
                        trailing: clear(const Key('clear-images'), () {
                          PaintingBinding.instance.imageCache
                            ..clear()
                            ..clearLiveImages();
                          setState(() {});
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _resetTraffic(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.resetTrafficConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('reset-traffic'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.reset),
          ),
        ],
      ),
    );
    if (ok == true) await settings.resetTraffic();
  }

  Future<void> _chooseQuality(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.uploadQuality,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GroupCard(
                children: [
                  for (final (key, title, hint) in [
                    ('standard', l.qualityStandard, l.qualityStandardHint),
                    ('high', l.qualityHigh, l.qualityHighHint),
                  ])
                    ListRow(
                      key: Key('quality-$key'),
                      lead: Icon(
                        settings.uploadQuality == key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: context.msg.primary,
                      ),
                      title: Text(title),
                      subtitle: Text(hint),
                      onTap: () => Navigator.of(context).pop(key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await settings.setUploadQuality(picked);
  }
}
