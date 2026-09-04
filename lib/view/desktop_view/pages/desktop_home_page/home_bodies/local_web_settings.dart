import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';

/// Turns the built-in web server on and off, and shows the addresses a phone
/// can reach it at.
class LocalWebSettings extends StatefulWidget {
  const LocalWebSettings({super.key});

  @override
  State<LocalWebSettings> createState() => _LocalWebSettingsState();
}

class _LocalWebSettingsState extends State<LocalWebSettings> {
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(text: context.read<LocalWebBloc>().state.port.toString());
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  void _applyPort() {
    final port = int.tryParse(_portController.text.trim());
    if (port == null) return;
    context.read<LocalWebBloc>().add(ChangeLocalWebPort(port));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalWebBloc, LocalWebState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'localWebDescription'.tr(),
              style: const TextStyle(fontSize: 12, color: AppColor.grey2Color),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: state.isRunning,
                  onChanged: state.isBusy
                      ? null
                      : (value) => context.read<LocalWebBloc>().add(
                            value ? const StartLocalWeb() : const StopLocalWeb(),
                          ),
                ),
                const SizedBox(width: 8),
                Text(state.isRunning ? 'localWebRunning'.tr() : 'localWebStopped'.tr()),
                const SizedBox(width: 24),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'localWebPort'.tr(),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyPort(),
                    onTapOutside: (_) => _applyPort(),
                  ),
                ),
              ],
            ),
            if (state.hasError) ...[
              const SizedBox(height: 8),
              Text(
                state.errorKey.tr(),
                style: const TextStyle(fontSize: 12, color: AppColor.alertErrorColor),
              ),
            ],
            if (state.isRunning) ...[
              const SizedBox(height: 16),
              if (state.addresses.isEmpty)
                Text(
                  'localWebNoNetwork'.tr(),
                  style: const TextStyle(fontSize: 12, color: AppColor.alertWarningDarkColor),
                )
              else
                _buildAddresses(context, state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAddresses(BuildContext context, LocalWebState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: QrImageView(
            data: state.primaryUrl,
            version: QrVersions.auto,
            size: 160,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'localWebScanHint'.tr(),
                style: const TextStyle(fontSize: 12, color: AppColor.grey2Color),
              ),
              const SizedBox(height: 8),
              // Several addresses mean several networks (Wi-Fi plus a cable, a
              // VPN, a virtual adapter). Which one the phone can reach is not
              // knowable from here, so all of them are offered.
              ...state.addresses.map((address) => _buildAddressRow(context, address.url(state.port), address.interfaceName)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.read<LocalWebBloc>().add(const RefreshLocalWebAddresses()),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('localWebRefreshAddresses'.tr(), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context, String url, String interfaceName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Flexible(
            child: SelectableText(
              url,
              style: const TextStyle(fontSize: 14, color: AppColor.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(interfaceName, style: const TextStyle(fontSize: 11, color: AppColor.grey3Color)),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'localWebCopyAddress'.tr(),
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
          ),
        ],
      ),
    );
  }
}
