import 'package:flutter/material.dart';

import '../data/repositories/profile_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/launch.dart';
import '../widgets/ui.dart';

/// Mon compte → Aide and À propos (owner's reference, 2026-10-26): FAQ,
/// call, WhatsApp, e-mail; website, privacy policy, terms. The contacts
/// and texts are the partner's (back-office → Plateforme); a row the
/// partner hasn't filled in says so instead of doing nothing.
class HelpAboutSection extends StatefulWidget {
  const HelpAboutSection({super.key});

  @override
  State<HelpAboutSection> createState() => _HelpAboutSectionState();
}

class _HelpAboutSectionState extends State<HelpAboutSection> {
  PlatformInfo _p = const PlatformInfo();
  AppSettings? _g;

  @override
  void initState() {
    super.initState();
    // The group's own contacts and rules (owner, 2026-11-02).
    RepositoryLocator.instance.profile
        .settings()
        .then((s) {
          if (mounted) setState(() => _g = s);
        })
        .catchError((_) {});
    RepositoryLocator.instance.profile
        .platform()
        .then((p) {
          if (mounted) setState(() => _p = p);
        })
        .catchError((_) {}); // offline: rows say "not available yet"
  }

  /// "654 85 81 38" → "237654858138" for wa.me (Cameroon numbers).
  static String _intl(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 9 ? '237$digits' : digits;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void open(Uri uri) => openUri(context, uri);
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final g = _g;
    final hasGroup =
        g != null &&
        (g.rulesText.isNotEmpty ||
            g.contactPhone.isNotEmpty ||
            g.contactEmail.isNotEmpty ||
            g.website.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasGroup) ...[
          SectionLabel(l.myGroupSection),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              if (g.rulesText.isNotEmpty)
                _HelpRow(
                  key: const Key('group-rules'),
                  icon: Icons.gavel_outlined,
                  title: l.groupRules,
                  onTap: () => push(
                    TextPageScreen(title: l.groupRules, text: g.rulesText),
                  ),
                ),
              if (g.contactPhone.isNotEmpty)
                _HelpRow(
                  key: const Key('group-call'),
                  icon: Icons.phone_outlined,
                  title: l.groupCall,
                  subtitle: g.contactPhone,
                  onTap: () => open(telUri('+${_intl(g.contactPhone)}')),
                ),
              if (g.contactEmail.isNotEmpty)
                _HelpRow(
                  key: const Key('group-mail'),
                  icon: Icons.mail_outline,
                  title: l.groupMail,
                  subtitle: g.contactEmail,
                  onTap: () =>
                      open(Uri(scheme: 'mailto', path: g.contactEmail)),
                ),
              if (g.website.isNotEmpty)
                _HelpRow(
                  key: const Key('group-link'),
                  icon: Icons.link,
                  title: l.groupLink,
                  subtitle: g.website,
                  onTap: () => open(Uri.parse(g.website)),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        SectionLabel(l.helpSection),
        const SizedBox(height: 8),
        GroupCard(
          children: [
            _HelpRow(
              key: const Key('help-faq'),
              icon: Icons.help_outline,
              title: l.faq,
              subtitle: l.faqSub,
              onTap: () => push(const FaqScreen()),
            ),
            _HelpRow(
              key: const Key('help-call'),
              icon: Icons.phone_outlined,
              title: l.helpSupport,
              subtitle: l.helpSupportSub,
              onTap: _p.supportPhone.isEmpty
                  ? null
                  : () => open(telUri('+${_intl(_p.supportPhone)}')),
            ),
            _HelpRow(
              key: const Key('help-whatsapp'),
              icon: Icons.chat_bubble_outline,
              title: l.whatsappSupport,
              subtitle: l.whatsappSupportSub,
              onTap: _p.supportWhatsapp.isEmpty
                  ? null
                  : () => open(
                      Uri.parse('https://wa.me/${_intl(_p.supportWhatsapp)}'),
                    ),
            ),
            _HelpRow(
              key: const Key('help-contact'),
              icon: Icons.person_outline,
              title: l.contactUs,
              subtitle: l.contactUsSub,
              onTap: _p.supportEmail.isEmpty
                  ? null
                  : () => open(
                      Uri(
                        scheme: 'mailto',
                        path: _p.supportEmail,
                        query: 'subject=Huddle',
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionLabel(l.aboutSection),
        const SizedBox(height: 8),
        GroupCard(
          children: [
            _HelpRow(
              key: const Key('about-website'),
              icon: Icons.language,
              title: l.visitWebsite,
              onTap: _p.website.isEmpty
                  ? null
                  : () => open(Uri.parse(_p.website)),
            ),
            _HelpRow(
              key: const Key('about-privacy'),
              icon: Icons.lock_outline,
              title: l.privacyPolicy,
              onTap: _p.privacyText.isEmpty
                  ? null
                  : () => push(
                      TextPageScreen(
                        title: l.privacyPolicy,
                        text: _p.privacyText,
                      ),
                    ),
            ),
            _HelpRow(
              key: const Key('about-terms'),
              icon: Icons.description_outlined,
              title: l.termsOfService,
              onTap: _p.termsText.isEmpty
                  ? null
                  : () => push(
                      TextPageScreen(
                        title: l.termsOfService,
                        text: _p.termsText,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Icon in a tinted square, title, subtitle, chevron (the reference rows).
/// Without [onTap] the row is greyed with "Pas encore disponible".
class _HelpRow extends StatelessWidget {
  const _HelpRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final off = onTap == null;
    return Opacity(
      opacity: off ? 0.55 : 1,
      child: ListRow(
        lead: Container(
          width: 44,
          height: 44,
          // The app's own colour (group's or the member's choice).
          decoration: BoxDecoration(
            color: c.primaryTint,
            borderRadius: BorderRadius.circular(MsgRadius.md),
          ),
          child: Icon(icon, color: c.primaryText, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: off
            ? Text(l.notAvailableYet)
            : (subtitle == null ? null : Text(subtitle!)),
        chevron: !off,
        onTap: onTap,
      ),
    );
  }
}

/// Questions fréquentes (owner, 2026-11-02): the group's own questions,
/// then the common ones (built into the app in both languages, plus those
/// the platform team adds), and "Proposer une question" for members.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  FaqData _data = const FaqData();
  List<FaqSuggestion> _mine = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = RepositoryLocator.instance.profile;
    repo
        .faq()
        .then((d) {
          if (mounted) setState(() => _data = d);
        })
        .catchError((_) {}); // offline: the built-in questions
    repo
        .myFaqSuggestions()
        .then((s) {
          if (mounted) setState(() => _mine = s);
        })
        .catchError((_) {});
  }

  Future<void> _suggest() async {
    final sent = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const FaqSuggestScreen()));
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final common = [
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
      (l.faqQ5, l.faqA5),
      (l.faqQ6, l.faqA6),
      ..._data.common,
    ];
    Widget card(List<FaqItem> items) => GroupCard(
      children: [
        for (final (q, a) in items)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                title: Text(
                  q,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(
                    a,
                    style: TextStyle(height: 1.5, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.faq, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_data.group.isNotEmpty) ...[
                    SectionLabel(l.faqGroupSection),
                    const SizedBox(height: 8),
                    KeyedSubtree(
                      key: const Key('faq-group'),
                      child: card(_data.group),
                    ),
                    const SizedBox(height: 24),
                    SectionLabel(l.faqCommonSection),
                    const SizedBox(height: 8),
                  ],
                  card(common),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('faq-suggest'),
                    onPressed: _suggest,
                    icon: const Icon(Icons.add_comment_outlined),
                    label: Text(l.faqSuggest),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.faqSuggestHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  if (_mine.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionLabel(l.faqMine),
                    const SizedBox(height: 8),
                    GroupCard(
                      children: [
                        for (final s in _mine)
                          ListRow(
                            key: Key('faq-mine-${s.id}'),
                            title: Text(s.question),
                            subtitle: s.note.isEmpty ? null : Text(s.note),
                            trailing: switch (s.status) {
                              'published' => Badge2(
                                l.faqPublished,
                                tone: Tone.green,
                              ),
                              'declined' => Badge2(
                                l.faqDeclined,
                                tone: Tone.neutral,
                              ),
                              _ => Badge2(l.faqPending, tone: Tone.amber),
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Proposer une question": a question and, if the member knows it, its
/// answer, for the platform team to correct and publish.
class FaqSuggestScreen extends StatefulWidget {
  const FaqSuggestScreen({super.key});

  @override
  State<FaqSuggestScreen> createState() => _FaqSuggestScreenState();
}

class _FaqSuggestScreenState extends State<FaqSuggestScreen> {
  final _form = GlobalKey<FormState>();
  final _q = TextEditingController();
  final _a = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await RepositoryLocator.instance.profile.suggestFaq(
        question: _q.text.trim(),
        answer: _a.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).faqSent)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.faqSuggest, back: true, small: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    TextFormField(
                      key: const Key('faq-question'),
                      controller: _q,
                      maxLength: 200,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l.faqQuestion),
                      validator: (v) => (v ?? '').trim().length < 5
                          ? l.faqQuestionRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('faq-answer'),
                      controller: _a,
                      maxLength: 3000,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: l.faqAnswer,
                        helperText: l.faqAnswerHint,
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('faq-send'),
                      onPressed: _busy ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(l.faqSend),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A long text written by the partner (privacy policy, terms).
class TextPageScreen extends StatelessWidget {
  const TextPageScreen({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          ScreenHeader(title: title, back: true, small: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                SelectionArea(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
