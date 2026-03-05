import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
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
          _buildUrlField(
            context: context,
            label: 'qrCurrentSongUrl'.tr(),
            value: state.qrCurrentSongUrl,
            settingsKey: 'qrCurrentSongUrl',
            icon: Icons.music_note,
          ),
          const SizedBox(height: 12),
          _buildUrlField(
            context: context,
            label: 'qrWebAppUrl'.tr(),
            value: state.qrWebAppUrl,
            settingsKey: 'qrWebAppUrl',
            icon: Icons.language,
          ),
          const SizedBox(height: 12),
          _buildUrlField(
            context: context,
            label: 'qrZizkoviUrl'.tr(),
            value: state.qrZizkoviUrl,
            settingsKey: 'qrZizkoviUrl',
            icon: Icons.home,
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
