import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../services/constants.dart';

class EditSheetsBody extends StatefulWidget {
  const EditSheetsBody({super.key});

  @override
  State<EditSheetsBody> createState() => _EditSheetsBodyState();
}

class _EditSheetsBodyState extends State<EditSheetsBody> {
  bool _isUploading = false;
  String _uploadStatus = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        final sheets = state.currentEditSong.sheets ?? [];
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('sheets'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        // Upload image button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _isUploading ? null : () => _uploadImage(context),
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: _isUploading ? Colors.grey : AppColor.primaryColor,
                                border: Border.all(color: AppColor.grey1Color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.upload_file, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('uploadSheet'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Add URL button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _showAddUrlDialog(context),
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor,
                                border: Border.all(color: AppColor.grey1Color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('addSheetUrl'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Save button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              margin: const EdgeInsets.only(left: 5, right: 5),
                              decoration: BoxDecoration(
                                color: state.isCurrentSongModified ? AppColor.primaryColor : AppColor.defaultBackgroundColor,
                                border: Border.all(color: AppColor.grey1Color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(child: Icon(Icons.save, size: 16, color: state.isCurrentSongModified ? Colors.white : Colors.black)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(_uploadStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // Sheets grid
              Expanded(
                child: sheets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('noSheetMessage'.tr(), style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _uploadImage(context),
                                  icon: const Icon(Icons.upload_file),
                                  label: Text('uploadSheet'.tr()),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddUrlDialog(context),
                                  icon: const Icon(Icons.link),
                                  label: Text('addSheetUrl'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: sheets.length,
                        itemBuilder: (context, index) {
                          final sheetUrl = sheets[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Sheet image
                                GestureDetector(
                                  onTap: () => _showFullImageDialog(context, sheetUrl, index, sheets.length),
                                  child: CachedNetworkImage(
                                    imageUrl: sheetUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        const SizedBox(height: 4),
                                        Text(
                                          'loadError'.tr(),
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Index label
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ),
                                // Delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        context.read<EditSongBloc>().add(RemoveSheet(index: index));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddUrlDialog(BuildContext context) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('addSheetUrl'.tr()),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'sheetImageUrl'.tr(),
                border: OutlineInputBorder(),
                hintText: 'https://...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isEmpty) return;
                context.read<EditSongBloc>().add(AddSheet(sheetUrl: urlController.text));
                Navigator.pop(dialogContext);
              },
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }
      if (fileBytes == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      setState(() {
        _isUploading = true;
        _uploadStatus = 'uploading'.tr();
      });

      final downloadUrl = await context.read<EditSongBloc>().songsRepository.uploadFile(fileName, fileBytes);

      if (mounted && downloadUrl != null) {
        context.read<EditSongBloc>().add(AddSheet(sheetUrl: downloadUrl));
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      } else if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('uploadError'.tr()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('uploadErrorDetail'.tr(args: [e.toString()])), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullImageDialog(BuildContext context, String imageUrl, int index, int total) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1} / $total',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
