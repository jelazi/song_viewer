// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:default_project/core/youtube_helper.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../model/youtube_video.dart';

class EditPageMobile extends StatefulWidget {
  const EditPageMobile({
    Key? key,
  }) : super(key: key);

  @override
  State<EditPageMobile> createState() => _EditPageMobileState();
}

class _EditPageMobileState extends State<EditPageMobile> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              _onWillPop(state);
              return;
            }
          },
          child: Scaffold(appBar: AppBar(
            title: BlocBuilder<EditSongBloc, EditSongState>(
              builder: (context, state) {
                return Text(
                  '${'editSong'.tr()} ${state.currentEditSong.title}',
                  style: h5TextStyle.copyWith(color: Colors.white),
                );
              },
            ),
          ), body: BlocBuilder<EditSongBloc, EditSongState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditRow(
                        typeValue: 'title'.tr(),
                        title: state.currentEditSong.title,
                        titleTextStyle: h3TextStyle,
                        editFunction: () {
                          showDialog(
                              context: context,
                              builder: ((context) {
                                return EditTextDialog(
                                  okClick: (value) {
                                    context.read<EditSongBloc>().add(ChangeSongValue(nameValue: 'title', value: value, appVersion: 'mobile'));
                                  },
                                  title: 'editTitle'.tr(),
                                  value: state.currentEditSong.title,
                                );
                              }));
                        }),
                    EditRow(
                        typeValue: 'interpret'.tr(),
                        title: state.currentEditSong.interpret,
                        titleTextStyle: labelTextStyle,
                        editFunction: () {
                          showDialog(
                              context: context,
                              builder: ((context) {
                                return EditTextDialog(
                                  okClick: (value) {
                                    context.read<EditSongBloc>().add(ChangeSongValue(nameValue: 'interpret', value: value, appVersion: 'mobile'));
                                  },
                                  title: 'editInterpret'.tr(),
                                  value: state.currentEditSong.interpret ?? '',
                                );
                              }));
                        }),
                    EditRow(
                        typeValue: 'indexSongBook'.tr(),
                        title: (state.currentEditSong.indexSongBook?.toString()),
                        titleTextStyle: labelTextStyle,
                        editFunction: () {
                          showDialog(
                              context: context,
                              builder: ((context) {
                                return EditNumberDialog(
                                  okClick: (value) {
                                    context.read<EditSongBloc>().add(ChangeSongValue(nameValue: 'indexSongBook', value: value, appVersion: 'mobile'));
                                  },
                                  title: 'indexSongBook'.tr(),
                                  value: state.currentEditSong.indexSongBook ?? 0,
                                );
                              }));
                        }),
                    EditRow(
                        typeValue: 'text'.tr(),
                        title: state.currentEditSong.lyrics,
                        titleTextStyle: labelTextStyle,
                        maxLines: 5,
                        editFunction: () {
                          Navigator.of(context).pushNamed('/editLyricPage');
                        },
                        chordEditFunction: () {
                          context.read<EditSongBloc>().add(const UpdateListUniqueChords(typeLyric: TypeLyric.translate));
                          Navigator.of(context).pushNamed('/editChordsPage');
                        }),
                    getGroups(context, state),
                    getTags(context, state),
                    EditRow(
                        typeValue: 'originalText'.tr(),
                        title: state.currentEditSong.originalLyrics,
                        titleTextStyle: labelTextStyle,
                        maxLines: 5,
                        editFunction: () {
                          Navigator.of(context).pushNamed('/editOriginalLyricPage');
                        },
                        chordEditFunction: () {
                          context.read<EditSongBloc>().add(const UpdateListUniqueChords(typeLyric: TypeLyric.original));
                          Navigator.of(context).pushNamed('/editOriginalChordsPage');
                        }),
                    getYoutubeVideosMobile(context, state),
                    getSheetsMobile(context, state),
                  ],
                ),
              );
            },
          )),
        );
      },
    );
  }

  Future<bool> _onWillPop(EditSongState state) async {
    final oldSong = context.read<EditSongBloc>().songsRepository.getSongById(state.currentEditSong.id);
    final listModified = oldSong?.checkModifiedSong(state.currentEditSong, false) ?? [];
    if (listModified.isNotEmpty) {
      return (await showDialog(
              context: context,
              builder: (BuildContext context) {
                return QuestionDialog(
                  title: 'saveChanges'.tr(),
                  question: listModified.toString() + 'saveChangesQuestion'.tr(),
                  okClick: () {
                    context.read<HomePageBloc>().add(UpdateSong(song: state.currentEditSong));
                    Navigator.of(context).pop(true);
                  },
                  cancelClick: () {
                    Navigator.of(context).pop(true);
                  },
                );
              }) ??
          false);
    }
    return true;
  }

  Widget getTags(BuildContext context, EditSongState state) {
    bool isNotEmptyOrNull = state.currentEditSong.tags != null && state.currentEditSong.tags!.isNotEmpty;
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: isNotEmptyOrNull ? AppColor.primaryColor : AppColor.grey3Color)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'tags'.tr()}:', style: labelTextStyle.copyWith(color: isNotEmptyOrNull ? AppColor.grey1Color : AppColor.grey2Color)),
              Row(
                mainAxisAlignment: isNotEmptyOrNull ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                        height: 30,
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                        child: const Center(child: Icon(Icons.add, color: AppColor.primaryColor))),
                  ),
                  isNotEmptyOrNull
                      ? Row(
                          children: state.currentEditSong.tags!
                              .map((e) => GestureDetector(
                                    onLongPress: () {},
                                    child: Container(
                                        height: 30,
                                        margin: const EdgeInsets.all(5),
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: AppColor.primaryLightestColor),
                                        child: Text(e, style: labelTextStyle.copyWith(color: Colors.white))),
                                  ))
                              .toList(),
                        )
                      : Container(),
                ],
              ),
            ],
          ),
        ));
  }
}

Widget getYoutubeVideosMobile(BuildContext context, EditSongState state) {
  bool isNotEmptyOrNull = state.currentEditSong.youtubeVideos != null && state.currentEditSong.youtubeVideos!.isNotEmpty;
  return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: isNotEmptyOrNull ? AppColor.primaryColor : AppColor.grey3Color)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'youtube'.tr()}:', style: labelTextStyle.copyWith(color: isNotEmptyOrNull ? AppColor.grey1Color : AppColor.grey2Color)),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddYoutubeDialogMobile(context),
                child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                    child: const Center(child: Icon(Icons.add, color: AppColor.primaryColor))),
              ),
            ],
          ),
          if (isNotEmptyOrNull)
            ...state.currentEditSong.youtubeVideos!.asMap().entries.map((entry) {
              final index = entry.key;
              final video = entry.value;
              final videoId = extractYoutubeVideoId(video.path);
              final isValid = videoId != null;
              return ListTile(
                dense: true,
                leading: Icon(
                  isValid ? Icons.play_circle_fill : Icons.error_outline,
                  color: isValid ? AppColor.primaryColor : Colors.red,
                ),
                title: Text(
                  video.name.isNotEmpty ? video.name : 'Video ${index + 1}',
                  style: labelTextStyle,
                ),
                subtitle: Text(
                  video.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: isValid ? Colors.grey : Colors.red),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isValid)
                      IconButton(
                        icon: const Icon(Icons.open_in_browser, color: AppColor.primaryColor, size: 20),
                        onPressed: () async {
                          final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      onPressed: () => _showEditYoutubeDialogMobile(context, index, video),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        context.read<EditSongBloc>().add(RemoveYoutubeVideo(index: index));
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ));
}

void _showAddYoutubeDialogMobile(BuildContext context) {
  final nameController = TextEditingController();
  final urlController = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('addYoutube'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'videoNameLabel'.tr(), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'YouTube URL', border: OutlineInputBorder(), hintText: 'https://www.youtube.com/watch?v=...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isEmpty) return;
              context.read<EditSongBloc>().add(AddYoutubeVideo(video: YoutubeVideo(name: nameController.text, path: urlController.text)));
              Navigator.pop(dialogContext);
            },
            child: Text('ok'.tr()),
          ),
        ],
      );
    },
  );
}

void _showEditYoutubeDialogMobile(BuildContext context, int index, YoutubeVideo video) {
  final nameController = TextEditingController(text: video.name);
  final urlController = TextEditingController(text: video.path);
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('editYoutubeVideo'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'videoNameLabel'.tr(), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'YouTube URL', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isEmpty) return;
              context.read<EditSongBloc>().add(UpdateYoutubeVideo(index: index, video: YoutubeVideo(name: nameController.text, path: urlController.text)));
              Navigator.pop(dialogContext);
            },
            child: Text('save'.tr()),
          ),
        ],
      );
    },
  );
}

Widget getSheetsMobile(BuildContext context, EditSongState state) {
  bool isNotEmptyOrNull = state.currentEditSong.sheets != null && state.currentEditSong.sheets!.isNotEmpty;
  return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: isNotEmptyOrNull ? AppColor.primaryColor : AppColor.grey3Color)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'sheets'.tr()}:', style: labelTextStyle.copyWith(color: isNotEmptyOrNull ? AppColor.grey1Color : AppColor.grey2Color)),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddSheetDialogMobile(context),
                child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                    child: const Center(child: Icon(Icons.add, color: AppColor.primaryColor))),
              ),
              GestureDetector(
                onTap: () => _uploadSheetImageMobile(context),
                child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_file, color: AppColor.primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text('uploadSheet'.tr(), style: const TextStyle(color: AppColor.primaryColor, fontSize: 12)),
                      ],
                    )),
              ),
            ],
          ),
          if (isNotEmptyOrNull)
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.currentEditSong.sheets!.length,
                itemBuilder: (context, index) {
                  final sheetUrl = state.currentEditSong.sheets![index];
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullSheetDialogMobile(context, sheetUrl),
                          child: SizedBox(
                            width: 110,
                            height: 150,
                            child: CachedNetworkImage(
                              imageUrl: sheetUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              context.read<EditSongBloc>().add(RemoveSheet(index: index));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
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
      ));
}

void _showAddSheetDialogMobile(BuildContext context) {
  final urlController = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('addSheetUrl'.tr()),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(labelText: 'URL obr\u00e1zku not', border: OutlineInputBorder(), hintText: 'https://...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
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

Future<void> _uploadSheetImageMobile(BuildContext context) async {
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

    final downloadUrl = await context.read<EditSongBloc>().songsRepository.uploadFile(fileName, fileBytes);

    if (context.mounted && downloadUrl != null) {
      context.read<EditSongBloc>().add(AddSheet(sheetUrl: downloadUrl));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('uploadErrorDetail'.tr(args: [e.toString()])), backgroundColor: Colors.red),
      );
    }
  }
}

void _showFullSheetDialogMobile(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64, color: Colors.grey),
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
          ],
        ),
      );
    },
  );
}

Widget getGroups(BuildContext context, EditSongState state) {
  bool isNotEmptyOrNull = state.currentEditSong.groups != null && state.currentEditSong.groups!.isNotEmpty;
  return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: isNotEmptyOrNull ? AppColor.primaryColor : AppColor.grey3Color)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'groups'.tr()}:', style: labelTextStyle.copyWith(color: isNotEmptyOrNull ? AppColor.grey1Color : AppColor.grey2Color)),
            Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                      height: 30,
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                      child: const Center(child: Icon(Icons.add, color: AppColor.primaryColor))),
                ),
                isNotEmptyOrNull
                    ? Row(
                        children: state.currentEditSong.groups!
                            .map((e) => GestureDetector(
                                  onLongPress: () {},
                                  child: Container(
                                      height: 30,
                                      margin: const EdgeInsets.all(5),
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: AppColor.primaryLightestColor),
                                      child: Text(e, style: labelTextStyle.copyWith(color: Colors.white))),
                                ))
                            .toList(),
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ));
}

// ignore: must_be_immutable
class EditRow extends StatelessWidget {
  final String typeValue;
  final String? title;
  final Function editFunction;
  final Function? chordEditFunction;
  final TextStyle titleTextStyle;
  int maxLines = 3;

  EditRow({
    Key? key,
    required this.typeValue,
    required this.title,
    required this.editFunction,
    required this.titleTextStyle,
    this.chordEditFunction,
    this.maxLines = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (title == null || title!.isEmpty) ? AppColor.grey3Color : AppColor.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$typeValue:', style: labelTextStyle.copyWith(color: (title == null || title!.isEmpty) ? AppColor.grey2Color : AppColor.grey1Color)),
          (title == null || title!.isEmpty)
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        editFunction();
                      },
                      child: Container(
                          height: 30,
                          width: 30,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4), color: Colors.white),
                          child: const Center(child: Icon(Icons.add, color: AppColor.primaryColor))),
                    ),
                  ))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          width: MediaQuery.of(context).size.width - 150,
                          child: Text(
                            title ?? '',
                            style: titleTextStyle,
                            softWrap: true,
                            maxLines: maxLines,
                          )),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                )),
                            onPressed: () => editFunction(),
                          ),
                        ),
                        if (chordEditFunction != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton(
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(MdiIcons.guitarAcoustic)),
                              onPressed: () => chordEditFunction!(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
