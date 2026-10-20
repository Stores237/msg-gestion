import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'attachments.dart';
import 'dates.dart';
import 'errors.dart';
import 'labels.dart';
import 'sync_widgets.dart';

/// Screen title row (design: .appbar).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.back = false,
    this.leading,
    this.actions = const [],
    this.small = false,
    this.sync = false,
  });

  /// Show the sync line under the header (tab root screens, design: SyncLine).
  final bool sync;
  final String title;
  final String? subtitle;
  final bool back;
  final Widget? leading;
  final List<Widget> actions;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          if (back)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l.back,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 8),
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: small ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
    if (!sync) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: SyncLine(),
        ),
      ],
    );
  }
}

/// Uppercase label above a group (design: .caps).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(action!, style: TextStyle(color: c.primaryText)),
            ),
        ],
      ),
    );
  }
}

/// White rounded card whose children are separated by hairlines (design: .card.list).
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MsgRadius.lg),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? const [
                BoxShadow(
                  color: Color(0x0D262420),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [BoxShadow(color: c.borderSubtle, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// List row: lead · title/subtitle · trailing (design: .row), ≥ 56 dp.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    this.lead,
    required this.title,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.onTap,
  });

  final Widget? lead;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (lead != null) ...[lead!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: c.textPrimary,
                    ),
                    child: title,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: c.textSecondary,
                        ),
                        child: subtitle!,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (chevron)
              Icon(Icons.chevron_right, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

enum Tone { green, amber, neutral, red }

/// Short uppercase status chip (design: DS Badge). Always text, never colour alone.
class Badge2 extends StatelessWidget {
  const Badge2(this.text, {super.key, this.tone = Tone.neutral});
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final (bg, fg) = switch (tone) {
      Tone.green => (c.primaryTint, c.primaryText),
      Tone.amber => (c.warnTint, c.warnText),
      Tone.red => (c.alertTint, c.alert),
      Tone.neutral => (c.surfaceSunken, c.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.44,
          color: fg,
        ),
      ),
    );
  }
}

Tone statusTone(String status) => switch (status) {
  'actif' => Tone.green,
  'conge' => Tone.amber,
  _ => Tone.neutral,
};

/// Initials avatar with a status dot (bottom right) and a globe for the
/// diaspora (top right) — design: MAvatar.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.status,
    this.diaspora = false,
    this.size = 44,
    this.photo,
  });

  /// Signed URL of the member's photo; initials when absent or failing.
  final String? photo;
  final String name;
  final String? status;
  final bool diaspora;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    final dot = switch (status) {
      'actif' => c.primary,
      'conge' => c.warn,
      null => null,
      _ => c.textTertiary,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary,
              shape: BoxShape.circle,
              border: Border.all(color: c.surfaceCard, width: 2),
            ),
            child: photo == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.36,
                    ),
                  )
                : ClipOval(
                    child: Image.network(
                      photo!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: size * 0.36,
                        ),
                      ),
                    ),
                  ),
          ),
          if (dot != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surfaceCard, width: 2),
                ),
              ),
            ),
          if (diaspora)
            Positioned(
              right: -3,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Icon(Icons.public, size: 11, color: c.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling filter chips with counts (design: SegmentedTabs).
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('filter-$i'),
                label: Text(label),
                selected: i == selected,
                onSelected: (_) => onSelected(i),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: i == selected ? Colors.white : c.textPrimary,
                ),
                selectedColor: c.ink800,
                backgroundColor: c.surfaceCard,
                side: i == selected
                    ? BorderSide.none
                    : BorderSide(color: c.borderSubtle),
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
        ],
      ),
    );
  }
}

/// Two/three-way pill toggle (design: .seg2).
class Seg2 extends StatelessWidget {
  const Seg2({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final (i, o) in options.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: InkWell(
                  key: Key('seg-$i'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? c.surfaceCard : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      o,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: i == selected ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon in a tinted rounded square (design: DS IconChip).
class IconChip extends StatelessWidget {
  const IconChip(
    this.icon, {
    super.key,
    this.tone = Tone.green,
    this.size = 40,
  });
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final (bg, fg) = switch (tone) {
      Tone.green => (c.primaryTint, c.primaryText),
      Tone.amber => (c.warnTint, c.warnText),
      Tone.red => (c.alertTint, c.alert),
      Tone.neutral => (c.surfaceSunken, c.textSecondary),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: size * 0.5, color: fg),
    );
  }
}

/// "Accès réservé" block: says what is hidden and who can see it.
class RestrictedBlock extends StatelessWidget {
  const RestrictedBlock({super.key, required this.text, this.title});
  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(MsgRadius.lg),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lock_outline, size: 20, color: c.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? l.restrictedTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.action,
    this.error = false,
  });
  final IconData icon;
  final String title;
  final String? text;
  final Widget? action;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: error ? c.alertTint : c.surfaceSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: error ? c.alert : c.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                text!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Loads [load] once, shows a spinner, an error with Retry, or [builder].
/// Pull-to-refresh calls [load] again.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (!mounted) return;
      if (_data == null) {
        setState(() => _error = e);
      } else {
        showErrorSnack(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          error: true,
          title: l.loadError,
          text: describeError(context, _error!),
          action: FilledButton(onPressed: _reload, child: Text(l.retry)),
        ),
      );
    }
    return widget.builder(context, _data as T, _reload);
  }
}

/// Date block + kind label + title + time/place/dress (design: EventCard).
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.fullDate = false,
  });
  final CalendarEvent event;
  final VoidCallback? onTap;
  final bool fullDate;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final e = event;
    Widget meta(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                fontFeatures: tabular,
              ),
            ),
          ),
        ],
      ),
    );
    return GroupCard(
      padding: EdgeInsets.zero,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MsgRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: BorderRadius.circular(MsgRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        d.weekdayShort(e.startsAt).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                      Text(
                        '${e.startsAt.day}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          fontFeatures: tabular,
                        ),
                      ),
                      Text(
                        d.monthShort(e.startsAt).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventKindLabel(l, e.kind).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: c.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      meta(
                        Icons.schedule,
                        fullDate
                            ? d.fullDateTime(e.startsAt)
                            : d.time(e.startsAt),
                      ),
                      if (e.place.isNotEmpty)
                        meta(Icons.place_outlined, e.place),
                      if (e.dress.isNotEmpty)
                        meta(Icons.checkroom_outlined, dressLabel(l, e.dress)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Announcement card (design: AnnCard).
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.item,
    this.onTap,
    this.onReads,
  });
  final Announcement item;
  final VoidCallback? onTap;
  final VoidCallback? onReads;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final a = item;
    return GroupCard(
      padding: EdgeInsets.zero,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MsgRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Badge2(
                      a.isConvocation ? l.kindConvocation : l.kindAnnouncement,
                      tone: a.isConvocation ? Tone.green : Tone.neutral,
                    ),
                    if (a.pinned) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.push_pin_outlined,
                        size: 14,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l.pinned,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      d.dayMonth(a.createdAt),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.unread)
                      Semantics(
                        label: l.unreadDot,
                        child: Container(
                          margin: const EdgeInsets.only(top: 7, right: 8),
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                if (a.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    a.body,
                    maxLines: onTap == null ? null : 2,
                    overflow: onTap == null ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                if (a.attachments.isNotEmpty)
                  AttachmentList(items: a.attachments),
                if (a.isConvocation && a.eventStartsAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 16,
                        color: c.primaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d.fullDateTime(a.eventStartsAt!),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.authorName ?? '',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ),
                    if (a.readCount != null)
                      InkWell(
                        onTap: onReads,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: c.textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.readBy(a.readCount!, a.audience ?? 0),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
