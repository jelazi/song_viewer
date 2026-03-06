import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/qr_link.dart';
import '../../../../../services/constants.dart';
import 'bracket_error_scanner.dart';

class GeneralSettingsBody extends StatelessWidget {
  const GeneralSettingsBody({super.key});

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
              // QR code URLs
              _buildSectionTitle('qrCodeTitle'.tr()),
              const SizedBox(height: 8),
              _buildQrUrlSettings(context, state),
              const SizedBox(height: 24),
              // AI enrichment API keys
              _buildSectionTitle('enrichApiKeysTitle'.tr()),
              const SizedBox(height: 8),
              _buildApiKeySettings(context, state),
              const SizedBox(height: 24),
              // Bracket error scanner
              _buildSectionTitle('bracketScanTitle'.tr()),
              const SizedBox(height: 8),
              const BracketErrorScanner(),
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
        ],
      ),
    );
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
}
