import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/finance.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/money.dart';
import '../../widgets/notice.dart';
import '../../widgets/ui.dart';

/// Quarterly report (design: "Rapport trimestriel · commissaire aux
/// comptes"): synthesis, income by category; validation is blocked while
/// entries of the quarter are still unchecked.
class ReportView extends StatefulWidget {
  const ReportView({super.key, required this.me, required this.header});
  final Me me;
  final Widget header;

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late int _year;
  late int _quarter;
  Key _key = UniqueKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _quarter = (now.month - 1) ~/ 3 + 1;
  }

  void _shift(int delta) {
    var q = _quarter + delta, y = _year;
    if (q < 1) {
      q = 4;
      y -= 1;
    } else if (q > 4) {
      q = 1;
      y += 1;
    }
    setState(() {
      _quarter = q;
      _year = y;
      _key = UniqueKey();
    });
  }

  Future<void> _validate() async {
    final l = AppLocalizations.of(context);
    try {
      await RepositoryLocator.instance.finances.validateReport(_year, _quarter);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.entryValidated)));
      setState(() => _key = UniqueKey());
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    return AsyncView<QuarterReport>(
      key: _key,
      load: () => RepositoryLocator.instance.finances.report(_year, _quarter),
      builder: (context, r, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            widget.header,
            Row(
              children: [
                IconButton(
                  tooltip: l.previousQuarter,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Text(
                    l.quarterReport(_quarter, _year),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.nextQuarter,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SectionLabel(l.summary),
            const SizedBox(height: 8),
            GroupCard(
              children: [
                ListRow(
                  title: Text(l.openingBalance),
                  subtitle: Text(d.fullDate(r.start)),
                  trailing: Amount(r.opening),
                ),
                ListRow(
                  title: Text(l.incomeLabel),
                  trailing: Amount(r.income, sign: true, color: c.primaryText),
                ),
                ListRow(
                  title: Text(l.expenseLabel),
                  trailing: Amount(-r.expense, sign: true),
                ),
                ListRow(
                  title: Text(l.closingBalance),
                  subtitle: Text(
                    d.fullDate(r.end.subtract(const Duration(days: 1))),
                  ),
                  trailing: Amount(
                    r.closing,
                    size: 17,
                    weight: FontWeight.w800,
                    key: const Key('closing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionLabel(l.incomeByCategory),
            const SizedBox(height: 8),
            GroupCard(
              children: [
                for (final k in incomeCategories)
                  ListRow(
                    title: Text(financeCategoryLabel(l, k)),
                    trailing: Amount(
                      r.incomeByCategory[k] ?? 0,
                      weight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (r.validatedBy != null)
              Notice(
                tone: NoticeTone.ok,
                text: l.reportValidatedBy(
                  r.validatedBy!,
                  d.fullDate(r.validatedAt!),
                ),
              )
            else ...[
              if (r.pending > 0)
                Notice(tone: NoticeTone.warn, text: l.pendingBlock(r.pending)),
              if (widget.me.can('finances.report', 'validate')) ...[
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('validate-report'),
                  onPressed: r.pending > 0 ? null : _validate,
                  child: Text(l.validateReport),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
