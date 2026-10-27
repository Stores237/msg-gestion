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

/// What is being dragged: a guard's assignment and the service it is in.
class CellDrag {
  const CellDrag(this.assignment, this.serviceId);
  final DutyAssignment assignment;
  final int serviceId;
}

/// A planning cell that can be dragged (hold a name) and dropped on
/// (design: "Maintenir pour glisser ; la case cible s’éclaire"). A free
/// cell takes the guard; a filled cell of the same service swaps the two;
/// a filled cell of another service doesn't accept the drop.
class DraggableCell extends StatelessWidget {
  const DraggableCell({
    super.key,
    required this.serviceId,
    required this.side,
    required this.slot,
    this.assignment,
    this.onTap,
    this.onDrop,
  });
  final int serviceId;
  final String side;
  final Slot slot;
  final DutyAssignment? assignment;
  final VoidCallback? onTap;
  final void Function(DutyAssignment, Slot)? onDrop;

  @override
  Widget build(BuildContext context) {
    final cell = PlanCell(side: side, assignment: assignment, onTap: onTap);
    final drop = onDrop;
    if (drop == null) return cell;
    final a = assignment;
    return DragTarget<CellDrag>(
      onWillAcceptWithDetails: (d) {
        final from = d.data;
        if (from.assignment.id == a?.id) return false;
        return a == null || from.serviceId == serviceId;
      },
      onAcceptWithDetails: (d) => drop(d.data.assignment, slot),
      builder: (context, hovering, _) {
        final target = PlanCell(
          side: side,
          assignment: a,
          onTap: onTap,
          highlight: hovering.isNotEmpty,
        );
        if (a == null) return target;
        return LongPressDraggable<CellDrag>(
          data: CellDrag(a, serviceId),
          // The lifted name, under the finger (design: tilted card).
          feedback: Transform.rotate(
            angle: -0.03,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 84,
                child: PlanCell(side: side, assignment: a, lifted: true),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: target),
          child: target,
        );
      },
    );
  }
}

/// One planning cell (design: .pcell): name + status mark, or "+ Libre".
class PlanCell extends StatelessWidget {
  const PlanCell({
    super.key,
    this.assignment,
    required this.side,
    this.onTap,
    this.highlight = false,
    this.lifted = false,
  });
  final DutyAssignment? assignment;
  final String side;
  final VoidCallback? onTap;

  /// A dragged name is over this cell: "Déposer ici", lit in the app colour.
  final bool highlight;

  /// Drawn under the finger while dragging.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final a = assignment;
    final conflict = a?.conflict ?? false;
    final empty = a == null;
    return Material(
      color: highlight
          ? c.primaryTint
          : lifted
          ? c.surfaceCard
          : empty
          ? Colors.transparent
          : (conflict ? c.alertTint : c.surfaceSunken),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: highlight || lifted
            ? BorderSide(color: c.primary, width: 2)
            : empty
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
                        highlight && empty
                            ? l.dropHere
                            : (empty ? l.freeSlot : a.memberName),
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
