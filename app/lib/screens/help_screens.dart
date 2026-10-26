import 'package:flutter/material.dart';

import '../data/repositories/profile_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
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

  @override
  void initState() {
    super.initState();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                        query: 'subject=MSG',
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
          decoration: BoxDecoration(
            color: c.warnTint,
            borderRadius: BorderRadius.circular(MsgRadius.md),
          ),
          child: Icon(icon, color: c.warn, size: 22),
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

/// Questions fréquentes: built into the app, in both languages.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final items = [
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
      (l.faqQ5, l.faqA5),
      (l.faqQ6, l.faqA6),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.faq, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  GroupCard(
                    children: [
                      for (final (q, a) in items)
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ExpansionTile(
                              title: Text(
                                q,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              expandedAlignment: Alignment.centerLeft,
                              children: [
                                Text(
                                  a,
                                  style: TextStyle(
                                    height: 1.5,
                                    color: c.textSecondary,
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
