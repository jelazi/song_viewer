import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../services/constants.dart';

class QrCodeDialog extends StatefulWidget {
  const QrCodeDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const QrCodeDialog(),
    );
  }

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  // Track which index is expanded (-1 = none, 0 = first expanded by default)
  int _expandedIndex = 0;

  // GlobalKeys for QR screenshot capture, keyed by index
  final Map<int, GlobalKey> _qrKeys = {};

  GlobalKey _getQrKey(int index) {
    return _qrKeys.putIfAbsent(index, () => GlobalKey());
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Rect? _getSharePositionFromContext(BuildContext ctx) {
    final renderObject = ctx.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    return null;
  }

  Future<void> _shareUrl(String url, BuildContext buttonContext) async {
    await SharePlus.instance.share(
      ShareParams(
        text: url,
        sharePositionOrigin: _getSharePositionFromContext(buttonContext),
      ),
    );
  }

  Future<void> _shareQrCode(GlobalKey key, String title, BuildContext buttonContext) async {
    try {
      final origin = _getSharePositionFromContext(buttonContext);
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'qr_code.png')],
          subject: title,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
    }
  }

  Widget _buildQrSection({
    required String title,
    required String url,
    required bool isExpanded,
    required VoidCallback onToggle,
    required GlobalKey qrKey,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColor.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.grey1Color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          RepaintBoundary(
            key: qrKey,
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _launchUrl(url),
            child: Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColor.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(
                builder: (btnContext) => OutlinedButton.icon(
                  onPressed: () => _shareUrl(url, btnContext),
                  icon: const Icon(Icons.share, size: 16),
                  label: Text('shareLink'.tr(), style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: AppColor.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (btnContext) => OutlinedButton.icon(
                  onPressed: () => _shareQrCode(qrKey, title, btnContext),
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: Text('shareQrCode'.tr(), style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: AppColor.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final links = state.qrLinks;

        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            decoration: const BoxDecoration(
              color: AppColor.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            height: 60,
            child: Center(
              child: Text(
                'qrCodeTitle'.tr(),
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (links.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'qrNoLinks'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...links.asMap().entries.expand((entry) {
                    final index = entry.key;
                    final link = entry.value;
                    return [
                      if (index > 0) const Divider(color: AppColor.grey3Color),
                      _buildQrSection(
                        title: link.label.isNotEmpty ? link.label : 'QR ${index + 1}',
                        url: link.url,
                        isExpanded: _expandedIndex == index,
                        onToggle: () {
                          setState(() {
                            _expandedIndex = _expandedIndex == index ? -1 : index;
                          });
                        },
                        qrKey: _getQrKey(index),
                      ),
                    ];
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
    );
  }
}
