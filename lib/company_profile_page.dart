import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'app_errors.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';

/// The user's own company identity, used to brand and watermark their BOQ PDFs.
class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    for (final key in CompanyProfile.keys) key: TextEditingController(),
  };

  Map<String, String> _countries = const {};
  String? _logoUrl;
  String? _newLogoPath;
  bool _removeLogo = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  static const _labels = {
    'company_name': (
      'Company Name *',
      'e.g. Riverside Builders Ltd',
      TextInputType.text,
    ),
    'registration_number': (
      'Registration Number',
      'e.g. 80020001234567',
      TextInputType.text,
    ),
    'tin': ('TIN (if applicable)', 'e.g. 1000123456', TextInputType.text),
    'city': ('District/City', 'e.g. city, town or market', TextInputType.text),
    'physical_address': (
      'Physical Address',
      'e.g. Plot 1, Main Street',
      TextInputType.streetAddress,
    ),
    'postal_address': (
      'Postal Address',
      'e.g. P.O. Box 1234',
      TextInputType.text,
    ),
    'telephone': ('Telephone', '+256 700 000 000', TextInputType.phone),
    'alt_telephone': (
      'Alternative Telephone',
      '+256 700 000 001',
      TextInputType.phone,
    ),
    'email': ('Email', 'info@example.com', TextInputType.emailAddress),
    'website': ('Website', 'https://example.com', TextInputType.url),
    'description': (
      'Company Description',
      'A short description of your business',
      TextInputType.multiline,
    ),
  };

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.api.companyProfile(),
        widget.api.countries(),
      ]);
      final profile = results[0] as CompanyProfile?;
      _countries = results[1] as Map<String, String>;
      if (profile != null) {
        for (final key in CompanyProfile.keys) {
          _controllers[key]!.text = profile.fields[key] ?? '';
        }
        _logoUrl = profile.logoUrl;
      }
    } on Object catch (error) {
      _loadError = friendlyError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      if (await File(picked.path).length() > 2 * 1024 * 1024) {
        _snack('The logo must be 2 MB or smaller.');
        return;
      }
      setState(() {
        _newLogoPath = picked.path;
        _removeLogo = false;
      });
    } on Object {
      _snack(
        'The photo library could not be opened. Check the app\'s photo permission.',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.api.saveCompanyProfile(
        {
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        },
        logoPath: _newLogoPath,
        removeLogo: _removeLogo,
      );
      setState(() {
        _logoUrl = saved.logoUrl;
        _newLogoPath = null;
        _removeLogo = false;
      });
      _snack('Company profile saved. New BOQ exports will use these details.');
    } on Object catch (error) {
      _snack(friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget? _logoImage({double size = 72}) {
    if (_newLogoPath != null) {
      return Image.file(
        File(_newLogoPath!),
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (_logoUrl != null && !_removeLogo) {
      return Image.network(
        _logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: size / 2),
      );
    }
    return null;
  }

  static const _fieldIcons = <String, IconData>{
    'company_name': Icons.business_outlined,
    'registration_number': Icons.numbers,
    'tin': Icons.receipt_outlined,
    'country': Icons.public,
    'city': Icons.location_city_outlined,
    'physical_address': Icons.location_on_outlined,
    'postal_address': Icons.markunread_mailbox_outlined,
    'telephone': Icons.phone_outlined,
    'alt_telephone': Icons.phone_forwarded_outlined,
    'email': Icons.email_outlined,
    'website': Icons.language,
    'description': Icons.notes_outlined,
  };

  /// Visual grouping of [CompanyProfile.keys]; any key not listed here is
  /// still rendered, in the last section.
  static const _sections = <(String, IconData, List<String>)>[
    (
      'Company details',
      Icons.business_outlined,
      ['company_name', 'registration_number', 'tin', 'description'],
    ),
    (
      'Location',
      Icons.place_outlined,
      ['country', 'city', 'physical_address', 'postal_address'],
    ),
    (
      'Contact',
      Icons.contact_phone_outlined,
      ['telephone', 'alt_telephone', 'email', 'website'],
    ),
  ];

  Widget _field(String key) =>
      key == 'country' ? _countryField() : _textField(key);

  List<Widget> _formSections() {
    final grouped = {for (final section in _sections) ...section.$3};
    final leftovers = CompanyProfile.keys
        .where((key) => !grouped.contains(key))
        .toList();
    final widgets = <Widget>[];
    for (var i = 0; i < _sections.length; i++) {
      final (title, icon, keys) = _sections[i];
      final sectionKeys = [
        ...keys.where(CompanyProfile.keys.contains),
        if (i == _sections.length - 1) ...leftovers,
      ];
      if (sectionKeys.isEmpty) continue;
      widgets
        ..add(
          SectionCard(
            title: title,
            icon: icon,
            spacing: AppSpacing.lg,
            children: [for (final key in sectionKeys) _field(key)],
          ),
        )
        ..add(const SizedBox(height: AppSpacing.lg));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: _loading
          ? const LoadingState()
          : _loadError != null
          ? ErrorState(error: _loadError, onRetry: _load)
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          title: 'PDF letterhead preview',
                          subtitle: 'How your details appear on exported BOQs',
                        ),
                        _preview(context),
                        const SizedBox(height: AppSpacing.sectionGap),
                        SectionCard(
                          title: 'Logo',
                          icon: Icons.image_outlined,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLow,
                                    border: Border.all(
                                      color: scheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child:
                                      _logoImage() ??
                                      Text(
                                        'No logo',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _pickLogo,
                                        icon: const Icon(Icons.upload),
                                        label: const Text('Choose logo'),
                                      ),
                                      if (_logoImage() != null)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: scheme.error,
                                          ),
                                          onPressed: () => setState(() {
                                            _newLogoPath = null;
                                            _removeLogo = true;
                                          }),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Remove'),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ..._formSections(),
                        const SizedBox(height: AppSpacing.sm),
                        LoadingButton(
                          label: 'Save Company Profile',
                          icon: Icons.save_outlined,
                          loading: _saving,
                          onPressed: _save,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'BOQs keep the company details they were first exported with, even if you change this profile later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _textField(String key) {
    final (label, hint, type) = _labels[key]!;
    return TextFormField(
      controller: _controllers[key],
      keyboardType: type,
      maxLines: key == 'description' ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: key == 'description' ? null : Icon(_fieldIcons[key]),
        alignLabelWithHint: key == 'description',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (key == 'company_name' && text.isEmpty) {
          return 'Company name is required.';
        }
        if (text.isEmpty) return null;
        if (key == 'email' &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Enter a valid email address.';
        }
        if ((key == 'telephone' || key == 'alt_telephone') &&
            !RegExp(r'^\+?[0-9 ()-]{6,40}$').hasMatch(text)) {
          return 'Enter a valid phone number, including the country code.';
        }
        return null;
      },
    );
  }

  Widget _countryField() {
    final current = _controllers['country']!.text;
    return DropdownButtonFormField<String>(
      initialValue: _countries.containsKey(current) ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(_fieldIcons['country']),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Select...')),
        for (final entry in _countries.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: (value) => _controllers['country']!.text = value ?? '',
    );
  }

  /// Letterhead preview matching the PDF header.
  Widget _preview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String field(String key) => _controllers[key]!.text.trim();
    final lines = [
      [
        field('physical_address'),
        field('city'),
        _countries[field('country')] ?? '',
      ].where((v) => v.isNotEmpty).join(', '),
      field('postal_address'),
      [
        field('telephone'),
        field('alt_telephone'),
      ].where((v) => v.isNotEmpty).join(' / '),
      [field('email'), field('website')].where((v) => v.isNotEmpty).join(' · '),
    ].where((line) => line.isNotEmpty);
    final logo = _logoImage(size: 48);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logo != null) ...[
                  logo,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field('company_name').isEmpty
                            ? 'Your Company Name'
                            : field('company_name'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final line in lines)
                        Text(
                          line,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  'BILL OF\nQUANTITIES',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                if (logo != null)
                  Center(
                    child: Opacity(opacity: .07, child: _logoImage(size: 80)),
                  ),
                Center(
                  child: Text(
                    'PDF preview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
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
