import 'package:song_viewer/services/constants.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';

class GroupsBody extends StatelessWidget {
  const GroupsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
        final groupCards = state.listAllGroups
            .map((group) => SizedBox(
                  width: 280,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColor.grey3Color),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColor.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.group, size: 16, color: AppColor.primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              group,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return EditTextDialog(
                                      title: 'editGroup'.tr(),
                                      value: group,
                                      okClick: (value) {
                                        context.read<HomePageBloc>().add(
                                              ChangeGroup(
                                                group: group,
                                                newGroup: value,
                                              ),
                                            );
                                      },
                                    );
                                  });
                            },
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return QuestionDialog(
                                        title: 'deleteGroup'.tr(),
                                        okClick: () {
                                          context.read<HomePageBloc>().add(DeleteGroup(group: group));
                                        },
                                        question: 'deleteGroupQuestion'.tr());
                                  });
                            },
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'manageGroups'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...groupCards,
                          if (state.listAllGroups.isNotEmpty) const SizedBox(width: 8),
                          SizedBox(
                            width: 280,
                            child: Material(
                              color: AppColor.primaryLightestColor,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        return EditTextDialog(
                                          value: '',
                                          title: 'addGroup'.tr(),
                                          okClick: (value) {
                                            context.read<HomePageBloc>().add(CreateGroup(group: value));
                                          },
                                        );
                                      });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColor.primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.add, size: 16, color: AppColor.primaryColor),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'addGroup'.tr(),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.primaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }
}
