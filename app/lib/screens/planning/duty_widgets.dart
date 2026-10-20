import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/planning.dart';
import '../../theme/tokens.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';

/// Status chip of a duty (design: DutyChip); red "Conflit" is the one
/// exception to "red = error" because it is one.
class DutyChip extends StatelessWidget {
  const DutyChip({super.key, required this.status, this.conflict = false});
  final String status;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (conflict) return Badge2(l.conflict, tone: Tone.red);
    return Badge2(
      dutyStatusLabel(l, status),
      tone: switch (status) {
        'conf' => Tone.green,
        'pend' => Tone.amber,
        _ => Tone.neutral,
      },
    );
  }
}

/// One planning cell (design: .pcell): name + status mark, or "+ Libre".
class PlanCell extends StatelessWidget {
  const PlanCell({super.key, this.assignment, required this.side, this.onTap});
  final DutyAssignment? assignment;
  final String side;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final a = assignment;
    final conflict = a?.conflict ?? false;
    final empty = a == null;
    return Material(
      color: empty
          ? Colors.transparent
          : (conflict ? c.alertTint : c.surfaceSunken),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: empty
            ? BorderSide(color: c.borderStrong, width: 1.5)
            : (conflict
                  ? BorderSide(color: c.alert, width: 2)
                  : BorderSide.none),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sideLabel(l, side).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        empty ? l.freeSlot : a.memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: empty ? FontWeight.w600 : FontWeight.w700,
                          color: empty ? c.textSecondary : c.textPrimary,
                        ),
                      ),
                    ),
                    if (a != null)
                      conflict
                          ? Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: c.alert,
                              semanticLabel: l.conflict,
                            )
                          : a.status == 'conf'
                          ? Icon(
                              Icons.check,
                              size: 12,
                              color: c.primaryText,
                              semanticLabel: l.dutyConfirmed,
                            )
                          : Semantics(
                              label: l.dutyPending,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: c.warn,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
