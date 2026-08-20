import 'package:default_project/config/features.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/qr_link.dart';
import '../../../../../providers/pocketbase_provider.dart';
import '../../../../../services/constants.dart';
import 'bracket_error_scanner.dart';

class GeneralSettingsBody extends StatefulWidget {
  const GeneralSettingsBody({super.key});

  @override
  State<GeneralSettingsBody> createState() => _GeneralSettingsBodyState();
}

class _GeneralSettingsBodyState extends State<GeneralSettingsBody> {
  late TextEditingController _pbUrlController;
  late TextEditingController _pbEmailController;
  late TextEditingController _pbPasswordController;
  bool _pbTestingConnection = false;
  String? _pbConnectionResult;
  bool _pbObscurePassword = true;

  @override
  void initState() {
    super.initState();
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    _pbUrlController = TextEditingController(text: pbProvider.config?.pocketbaseUrl ?? '');
    _pbEmailController = TextEditingController(text: pbProvider.config?.email ?? '');
    _pbPasswordController = TextEditingController(text: pbProvider.config?.password ?? '');
  }

  @override
  void dispose() {
    _pbUrlController.dispose();
    _pbEmailController.dispose();
    _pbPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'generalSettings'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Local-first builds get this section at the bottom instead, as a
              // collapsed advanced block — see _buildOwnServerSection.
              if (Features.sharedServer) ...[
                _buildSectionTitle('pbSettingsTitle'.tr()),
                const SizedBox(height: 8),
                _buildPocketBaseSettings(context),
                const SizedBox(height: 24),
              ],
              // QR code URLs
              _buildSectionTitle('qrCodeTitle'.tr()),
              const SizedBox(height: 8),
              _buildQrUrlSettings(context, state),
              const SizedBox(height: 24),
              // AI enrichment API keys — personal flavour only. The store build
              // has no enrichment screen, so offering the keys there would ask
              // the user to configure a feature that is not in the artifact
              // (§10, blocker B2 item 3).
              if (Features.aiEnrichment) ...[
                _buildSectionTitle('enrichApiKeysTitle'.tr()),
                const SizedBox(height: 8),
                _buildApiKeySettings(context, state),
                const SizedBox(height: 24),
              ],
              // Bracket error scanner
              _buildSectionTitle('bracketScanTitle'.tr()),
              const SizedBox(height: 8),
              const BracketErrorScanner(),
              const SizedBox(height: 24),
              // Superuser mode
              _buildSectionTitle('superuserMode'.tr()),
              const SizedBox(height: 8),
              _buildSuperuserModeToggle(context, state),
              if (!Features.sharedServer) ...[
                const SizedBox(height: 24),
                _buildOwnServerSection(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  /// The server settings as a collapsed opt-in, for builds that are not wired
  /// to a shared server.
  Widget _buildOwnServerSection(BuildContext context) {
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: Icon(
          pbProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
          color: pbProvider.isConnected ? AppColor.alertSuccessColor : AppColor.grey2Color,
        ),
        title: Text(
          'ownServerTitle'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          pbProvider.isConnected ? (pbProvider.config?.pocketbaseUrl ?? '') : 'ownServerNotConnected'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColor.grey2Color),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'ownServerDescription'.tr(),
              style: const TextStyle(fontSize: 12, color: AppColor.grey2Color),
            ),
          ),
          _buildPocketBaseSettings(context),
        ],
      ),
    );
  }

  Widget _buildQrUrlSettings(BuildContext context, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...state.qrLinks.asMap().entries.map((entry) {
            final index = entry.key;
            final link = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: _buildQrLinkRow(context, index, link),
            );
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showAddQrLinkDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text('qrAddLink'.tr(), style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrLinkRow(BuildContext context, int index, QrLink link) {
    final labelController = TextEditingController(text: link.label);
    final urlController = TextEditingController(text: link.url);

    void save() {
      context.read<SettingsBloc>().add(
            UpdateQrLink(index, labelController.text, urlController.text),
          );
    }

    return Row(
      children: [
        const Icon(Icons.qr_code, size: 18, color: AppColor.grey2Color),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: labelController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColor.grey3Color),
              ),
              hintText: 'qrLabelHint'.tr(),
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onSubmitted: (_) => save(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: urlController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColor.grey3Color),
              ),
              hintText: 'https://',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => save(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.save, size: 18),
          tooltip: 'save'.tr(),
          onPressed: save,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          tooltip: 'qrRemoveLink'.tr(),
          onPressed: () {
            context.read<SettingsBloc>().add(RemoveQrLink(index));
          },
        ),
      ],
    );
  }

  void _showAddQrLinkDialog(BuildContext context) {
    final labelController = TextEditingController();
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('qrAddLink'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'qrLabelHint'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                context.read<SettingsBloc>().add(
                      AddQrLink(labelController.text, urlController.text),
                    );
                Navigator.pop(ctx);
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySettings(BuildContext context, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUrlField(
            context: context,
            label: 'enrichGroqApiKey'.tr(),
            value: state.groqApiKey,
            settingsKey: 'groqApiKey',
            icon: Icons.psychology,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildUrlField(
            context: context,
            label: 'enrichYoutubeApiKey'.tr(),
            value: state.youtubeApiKey,
            settingsKey: 'youtubeApiKey',
            icon: Icons.play_circle,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildUrlField(
            context: context,
            label: 'enrichGeminiApiKey'.tr(),
            value: state.geminiApiKey,
            settingsKey: 'geminiApiKey',
            icon: Icons.auto_awesome,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final buffer = StringBuffer();
                if (state.groqApiKey.isNotEmpty) {
                  buffer.writeln('Groq API: ${state.groqApiKey}');
                }
                if (state.youtubeApiKey.isNotEmpty) {
                  buffer.writeln('YouTube API: ${state.youtubeApiKey}');
                }
                if (state.geminiApiKey.isNotEmpty) {
                  buffer.writeln('Gemini API: ${state.geminiApiKey}');
                }
                if (buffer.isEmpty) return;
                Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('exportApiKeysCopied'.tr()),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text('exportApiKeys'.tr(), style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPocketBaseSettings(BuildContext context) {
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status indicator
          Row(
            children: [
              Icon(
                pbProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 18,
                color: pbProvider.isConnected ? AppColor.alertSuccessColor : AppColor.alertErrorColor,
              ),
              const SizedBox(width: 8),
              Text(
                pbProvider.isConnected ? 'pbConnectionSuccess'.tr() : 'pbConnectionFailed'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: pbProvider.isConnected ? AppColor.alertSuccessDarkColor : AppColor.alertErrorDarkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // URL field
          Row(
            children: [
              const Icon(Icons.dns, size: 18, color: AppColor.grey2Color),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: Text('pbUrl'.tr(), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pbUrlController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'http://127.0.0.1:8090',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Email field
          Row(
            children: [
              const Icon(Icons.email, size: 18, color: AppColor.grey2Color),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: Text('pbEmail'.tr(), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pbEmailController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'admin@example.com',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Password field
          Row(
            children: [
              const Icon(Icons.lock, size: 18, color: AppColor.grey2Color),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: Text('pbPassword'.tr(), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _pbPasswordController,
                  style: const TextStyle(fontSize: 13),
                  obscureText: _pbObscurePassword,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    suffixIcon: IconButton(
                      icon: Icon(_pbObscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
                      onPressed: () => setState(() => _pbObscurePassword = !_pbObscurePassword),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pbTestingConnection ? null : () => _testPbConnection(context),
                icon: _pbTestingConnection
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.wifi_find, size: 16, color: Colors.white),
                label: Text('pbTestConnection'.tr(), style: const TextStyle(fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _savePbSettings(context),
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                label: Text('pbSaveSettings'.tr(), style: const TextStyle(fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          if (_pbConnectionResult != null) ...[
            const SizedBox(height: 8),
            Text(
              _pbConnectionResult!,
              style: TextStyle(
                fontSize: 12,
                color: _pbConnectionResult == 'pbConnectionSuccess'.tr() ? AppColor.alertSuccessDarkColor : AppColor.alertErrorDarkColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testPbConnection(BuildContext context) async {
    setState(() {
      _pbTestingConnection = true;
      _pbConnectionResult = null;
    });
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    final testConfig = PocketBaseConfig(
      pocketbaseUrl: _pbUrlController.text.trim(),
      email: _pbEmailController.text.trim(),
      password: _pbPasswordController.text,
    );
    final success = await pbProvider.testConnection(testConfig);
    setState(() {
      _pbTestingConnection = false;
      _pbConnectionResult = success ? 'pbConnectionSuccess'.tr() : 'pbConnectionFailed'.tr();
    });
  }

  Future<void> _savePbSettings(BuildContext context) async {
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    final newConfig = PocketBaseConfig(
      pocketbaseUrl: _pbUrlController.text.trim(),
      email: _pbEmailController.text.trim(),
      password: _pbPasswordController.text,
    );
    final success = await pbProvider.reconnect(newConfig);
    if (context.mounted) {
      setState(() {
        _pbConnectionResult = success ? 'pbConnectionSuccess'.tr() : 'pbConnectionFailed'.tr();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'pbSettingsSaved'.tr() : 'pbConnectionFailed'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildUrlField({
    required BuildContext context,
    required String label,
    required String value,
    required String settingsKey,
    required IconData icon,
    bool obscureText = false,
  }) {
    final controller = TextEditingController(text: value);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColor.grey2Color),
        const SizedBox(width: 8),
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            obscureText: obscureText,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColor.grey3Color),
              ),
              hintText: obscureText ? 'API key...' : 'https://',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            keyboardType: obscureText ? TextInputType.text : TextInputType.url,
            onSubmitted: (newValue) {
              context.read<SettingsBloc>().add(ChangeSettingsValue(settingsKey, newValue));
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.save, size: 18),
          tooltip: 'save'.tr(),
          onPressed: () {
            context.read<SettingsBloc>().add(ChangeSettingsValue(settingsKey, controller.text));
          },
        ),
      ],
    );
  }

  Widget _buildSuperuserModeToggle(BuildContext context, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, size: 20, color: AppColor.grey1Color),
          const SizedBox(width: 12),
          Expanded(
            child: Text('superuserMode'.tr(), style: const TextStyle(fontSize: 14)),
          ),
          Switch.adaptive(
            value: state.superuserMode,
            onChanged: (value) {
              context.read<SettingsBloc>().add(ChangeSettingsValue('superuserMode', value));
              context.read<HomePageBloc>().add(const UpdateSettingsData());
            },
          ),
        ],
      ),
    );
  }
}
