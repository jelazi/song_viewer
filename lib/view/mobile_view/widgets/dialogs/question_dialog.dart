// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../services/constants.dart';

// ignore: must_be_immutable
class QuestionDialog extends StatelessWidget {
  final String title;

  final Function okClick;
  final Function? cancelClick;
  final String question;
  double height = 200;
  double width = 400;
  bool okBack = true;
  QuestionDialog({
    super.key,
    required this.title,
    required this.okClick,
    this.cancelClick,
    required this.question,
    this.height = 200,
    this.width = 400,
    this.okBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        decoration: const BoxDecoration(
            color: AppColor.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            )),
        height: 60,
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      contentPadding: const EdgeInsets.all(5.0),
      content: Container(
        padding: const EdgeInsets.all(8),
        height: height,
        width: width,
        child: Column(children: [
          const SizedBox(
            height: 20,
          ),
          Text(question),
          const SizedBox(
            height: 60,
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColor.primaryColor)),
                    onPressed: cancelClick != null ? () => cancelClick!() : () => Navigator.of(context).pop(),
                    child: Text(('no').tr(), style: const TextStyle(color: Colors.white))),
                ElevatedButton(
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(AppColor.primaryColor)),
                    onPressed: () {
                      if (okBack) {
                        Navigator.of(context).pop();
                      }
                      okClick();
                    },
                    child: Text(('yes').tr(), style: const TextStyle(color: Colors.white))),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
