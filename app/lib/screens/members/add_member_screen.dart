import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/member.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';

/// "Ajouter un membre". Under 18 → the parent block becomes required.
/// On success, the temporary PIN is shown once to hand over in person.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _form = GlobalKey<FormState>();
  final _last = TextEditingController();
  final _first = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _parentName = TextEditingController();
  final _parentRelation = TextEditingController();
  final _parentPhone = TextEditingController();
  DateTime? _birth;
  bool _diaspora = false;
  bool _feePaid = true;
  XFile? _photo;
  bool _busy = false;
  String? _phoneServerError;

  @override
  void dispose() {
    for (final c in [
      _last,
      _first,
      _phone,
      _city,
      _parentName,
      _parentRelation,
      _parentPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _age {
    final b = _birth;
    if (b == null) return null;
    final now = DateTime.now();
    return now.year -
        b.year -
        ((now.month < b.month || (now.month == b.month && now.day < b.day))
            ? 1
            : 0);
  }

  bool get _isMinor => (_age ?? 99) < 18;

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 15),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    setState(() => _phoneServerError = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final m = await RepositoryLocator.instance.members.create(
        NewMember(
          lastName: _last.text.trim(),
          firstName: _first.text.trim(),
          phone: _phone.text.trim(),
          birthDate: _birth,
          isDiaspora: _diaspora,
          city: _diaspora ? _city.text.trim() : '',
          parentName: _isMinor ? _parentName.text.trim() : '',
          parentRelation: _isMinor ? _parentRelation.text.trim() : '',
          parentPhone: _isMinor ? _parentPhone.text.trim() : '',
          registrationPaid: _feePaid,
        ),
      );
      if (_photo != null) {
        try {
          await RepositoryLocator.instance.members.uploadPhoto(
            m.summary.id,
            bytes: await _photo!.readAsBytes(),
            filename: _photo!.name,
          );
        } catch (_) {
          // The member exists; the photo can be added from the profile.
        }
      }
      if (!mounted) return;
      setState(
        () => _busy = false,
      ); // saved: stop the spinner behind the dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l.memberSavedTitle),
          content: Text(
            l.memberSavedPin(m.summary.fullName, m.temporaryPin ?? '—'),
            key: const Key('temp-pin'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.json?.containsKey('phone') == true) {
        setState(() => _phoneServerError = l.phoneTaken);
      } else if (mounted) {
        showErrorSnack(context, e);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l.required : null;
    String? phoneCheck(String? v) {
      final digits = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) return l.required;
      if (digits.length < 8 || digits.length > 15) return l.phoneInvalid;
      return null;
    }

    InputDecoration deco({
      String? hint,
      Widget? prefix,
      String? errorText,
      String? helper,
    }) => InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      errorText: errorText,
      helperText: helper,
      helperMaxLines: 2,
      errorMaxLines: 2,
      filled: true,
      fillColor: c.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
    );
    Widget label(String text, {bool req = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          children: [
            if (req)
              TextSpan(
                text: ' *',
                style: TextStyle(color: c.alert),
              ),
          ],
        ),
      ),
    );
    final phoneFormat = [FilteringTextInputFormatter.allow(RegExp(r'[\d +]'))];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.newMember, back: true, small: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          key: const Key('f-photo'),
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final p = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              imageQuality: 85,
                            );
                            if (p != null) setState(() => _photo = p);
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surfaceCard,
                              border: Border.all(
                                color: c.borderStrong,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _photo == null
                                  ? Icons.photo_camera_outlined
                                  : Icons.check,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _photo == null ? l.addPhoto : _photo!.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    label(l.lastNameLabel, req: true),
                    TextFormField(
                      key: const Key('f-last'),
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      validator: required,
                      decoration: deco(),
                    ),
                    label(l.firstNamesLabel, req: true),
                    TextFormField(
                      key: const Key('f-first'),
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      validator: required,
                      decoration: deco(),
                    ),
                    label(l.phoneLabel, req: true),
                    TextFormField(
                      key: const Key('f-phone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: phoneFormat,
                      validator: phoneCheck,
                      decoration: deco(
                        hint: '6 XX XX XX XX',
                        prefix: const Icon(Icons.phone_outlined),
                        errorText: _phoneServerError,
                      ),
                    ),
                    label(l.birthDate),
                    InkWell(
                      key: const Key('f-birth'),
                      onTap: _pickBirth,
                      child: InputDecorator(
                        decoration: deco(
                          prefix: const Icon(Icons.calendar_today_outlined),
                          helper: _isMinor && _age != null
                              ? l.ageMinorHint(_age!)
                              : null,
                        ),
                        child: Text(
                          _birth == null
                              ? l.birthDateHint
                              : Dates(context).fullDate(_birth!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _birth == null
                                ? c.textTertiary
                                : c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_isMinor) ...[
                      label(l.parentPhone, req: true),
                      TextFormField(
                        key: const Key('f-parent-phone'),
                        controller: _parentPhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: phoneFormat,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? l.parentRequired
                            : phoneCheck(v),
                        decoration: deco(
                          hint: '6 XX XX XX XX',
                          prefix: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      label(l.parentName),
                      TextFormField(
                        controller: _parentName,
                        textCapitalization: TextCapitalization.words,
                        decoration: deco(),
                      ),
                      label(l.parentRelation),
                      TextFormField(
                        controller: _parentRelation,
                        decoration: deco(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      key: const Key('f-fee'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.registrationFee,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(l.registrationFeeSub),
                      value: _feePaid,
                      onChanged: (v) => setState(() => _feePaid = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.diasporaMember,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: _diaspora,
                      onChanged: (v) => setState(() => _diaspora = v),
                    ),
                    if (_diaspora) ...[
                      label(l.cityCountry),
                      TextFormField(
                        controller: _city,
                        decoration: deco(hint: 'Lyon, France'),
                      ),
                    ],
                  ],
                ),
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
                  key: const Key('save-member'),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.saveMember),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
