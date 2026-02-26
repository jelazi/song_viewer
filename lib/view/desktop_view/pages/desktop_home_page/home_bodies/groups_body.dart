import 'package:default_project/services/constants.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';

class GroupsBody extends StatelessWidget {
  const GroupsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
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
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: state.listAllGroups
                          .map((group) => SizedBox(
                                width: 300,
                                child: Card(
                                  child: ListTile(
                                    title: Text(group),
                                    trailing: SizedBox(
                                      width: 150,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
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
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return QuestionDialog(
                                                        title: 'deleteGroup'.tr(),
                                                        okClick: () {
                                                          context.read<HomePageBloc>().add(DeleteGroup(group: group));
                                                        },
                                                        question: 'deleteGroupQuestion'.tr());
                                                  });
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 300,
                        child: Card(
                            color: AppColor.primaryLightestColor,
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return EditTextDialog(
                                        value: '',
                                        title: 'addGroup'.tr(),
                                        okClick: (value) {
                                          context.read<HomePageBloc>().add(CreateGroup(group: value));
                                        },
                                      );
                                    });
                              },
                              title: Text('addGroup'.tr()),
                              trailing: const Icon(Icons.add),
                            )))),
              ],
            ),
          ),
        ]);
      },
    );
  }
}
