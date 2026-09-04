import 'package:song_viewer/services/constants.dart';
import 'package:song_viewer/view/desktop_view/widgets/my_toast.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/user.dart';

class UsersBody extends StatefulWidget {
  const UsersBody({super.key});

  @override
  State<UsersBody> createState() => _UsersBodyState();
}

class _UsersBodyState extends State<UsersBody> {
  List<String> typeUsers = [
    TypeUser.admin.name,
    TypeUser.viewer.name,
    TypeUser.editor.name,
    TypeUser.superuser.name,
  ];
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Text(
                    'users'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                width: 300,
                child: ListView(children: [
                  Card(
                      child: ListTile(
                    onTap: () {
                      TextEditingController nameController = TextEditingController();
                      TextEditingController passwordController = TextEditingController();

                      showDialog(
                          context: context,
                          builder: (context) {
                            List<String> choiceGroups = [];

                            String nameTypeUser = TypeUser.admin.name;

                            return StatefulBuilder(builder: (context, setState) {
                              return EditDialog(
                                  height: 500,
                                  title: 'addUser'.tr(),
                                  okBack: false,
                                  okClick: () {
                                    if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                                      MyToast.showText(text: 'fieldEmpty'.tr(), typeNotification: TypeNotification.error);
                                      return;
                                    }
                                    context.read<UsersBloc>().add(AddUser(
                                        user: User(nameController.text, passwordController.text)
                                          ..allowedGroup = choiceGroups
                                          ..typeUser = User.getTypeUserByName(nameTypeUser)));
                                    Navigator.of(context).pop();
                                  },
                                  widgetContent: getUserDialogContent(nameController, passwordController, typeUsers, nameTypeUser, setState, choiceGroups, true));
                            });
                          });
                    },
                    title: Text('addUser'.tr()),
                    trailing: Icon(Icons.add),
                  )),
                  ...state.users
                      .map((e) => Card(
                              child: ListTile(
                            title: Text(e.name),
                            trailing: SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      TextEditingController nameController = TextEditingController(text: e.name);
                                      TextEditingController passwordController = TextEditingController(text: e.password);
                                      String nameTypeUser = e.typeUser.name;
                                      List<String> choiceGroups = e.allowedGroup;

                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return StatefulBuilder(builder: (context, setState) {
                                              return EditDialog(
                                                  okBack: false,
                                                  title: 'editUser'.tr(),
                                                  height: 500,
                                                  okClick: () {
                                                    if (nameController.text.isEmpty || passwordController.text.isEmpty) {
                                                      MyToast.showText(text: 'fieldEmpty'.tr(), typeNotification: TypeNotification.error);
                                                      return;
                                                    }
                                                    context.read<UsersBloc>().add(UpdateUser(
                                                        user: User(e.name, passwordController.text)
                                                          ..allowedGroup = e.allowedGroup
                                                          ..typeUser = User.getTypeUserByName(nameTypeUser)));
                                                    Navigator.of(context).pop();
                                                  },
                                                  widgetContent: getUserDialogContent(nameController, passwordController, typeUsers, nameTypeUser, setState, choiceGroups, false));
                                            });
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
                                              title: 'deleteUser'.tr(),
                                              okClick: () {
                                                context.read<UsersBloc>().add(DeleteUser(user: e));
                                              },
                                              question: '${'deleteUserQuestion'.tr()} ${e.name}?',
                                            );
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
                          )))
                      
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  SizedBox getUserDialogContent(TextEditingController nameController, TextEditingController passwordController, List<String> typeUsers, String nameTypeUser, StateSetter setState,
      List<String> choiceGroups, bool isNew) {
    return SizedBox(
      height: 380,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: isNew
                  ? TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    )
                  : Text(nameController.text, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: DropdownButton(
                  dropdownColor: Colors.white,
                  items: typeUsers.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  value: nameTypeUser,
                  onChanged: (value) {
                    setState(() {
                      nameTypeUser = value ?? nameTypeUser;
                    });
                  }),
            ),
            BlocBuilder<HomePageBloc, HomePageState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                      children: state.listAllGroups
                          .map((e) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ChoiceChip(
                                  selectedColor: AppColor.primaryColor,
                                  checkmarkColor: choiceGroups.contains(e) ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.all(8),
                                  label: Text(e, style: TextStyle(color: choiceGroups.contains(e) ? Colors.white : Colors.black)),
                                  selected: choiceGroups.contains(e),
                                  onSelected: (value) {
                                    setState(() {
                                      if (value) {
                                        choiceGroups.add(e);
                                      } else {
                                        choiceGroups.remove(e);
                                      }
                                    });
                                  },
                                ),
                              ))
                          .toList()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
