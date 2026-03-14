import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/constants.dart';

class SyncScreen extends StatelessWidget {
  final SyncInfo syncInfo;
  final VoidCallback onDownloadFromServer;
  final VoidCallback onStartEmpty;
  final bool isLoading;

  const SyncScreen({
    super.key,
    required this.syncInfo,
    required this.onDownloadFromServer,
    required this.onStartEmpty,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    final maxWidth = isDesktop ? 500.0 : double.infinity;
    final padding = isDesktop ? 48.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColor.defaultBackgroundColor,
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.all(padding),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: isLoading ? _buildLoadingContent() : _buildSyncOptions(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sync, size: 48, color: AppColor.primaryColor),
        const SizedBox(height: 24),
        Text(
          'syncInProgress'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.grey1Color,
          ),
        ),
        const SizedBox(height: 16),
        const CircularProgressIndicator(color: AppColor.primaryColor),
      ],
    );
  }

  Widget _buildSyncOptions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_outlined, size: 48, color: AppColor.primaryColor),
        const SizedBox(height: 24),
        Text(
          'syncTitle'.tr(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColor.grey1Color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'syncDescription'.tr(),
          style: const TextStyle(
            fontSize: 14,
            color: AppColor.grey2Color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildServerInfo(),
        const SizedBox(height: 32),

        // Download from server button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onDownloadFromServer,
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: Text(
              'syncDownload'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Start with empty database button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onStartEmpty,
            icon: const Icon(Icons.folder_open, color: AppColor.primaryColor),
            label: Text(
              'syncStartEmpty'.tr(),
              style: const TextStyle(color: AppColor.primaryColor, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColor.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.grey5Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.music_note, 'songs'.tr(), syncInfo.serverSongCount),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.playlist_play, 'playlists'.tr(), syncInfo.serverPlaylistCount),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.people, 'users'.tr(), syncInfo.serverUserCount),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.group_work, 'groups'.tr(), syncInfo.serverGroupCount),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, int count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColor.grey2Color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColor.grey2Color)),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColor.grey1Color),
        ),
      ],
    );
  }
}
