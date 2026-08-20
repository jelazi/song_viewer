import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SelectDialog extends StatelessWidget {
  String title;
  String selectQuestion;
  String firstSelectTitle;
  String secondSelectTitle;
  Function firstSelectFunction;
  Function secondSelectFunction;
  SelectDialog({
    super.key,
    required this.title,
    required this.selectQuestion,
    required this.firstSelectTitle,
    required this.secondSelectTitle,
    required this.firstSelectFunction,
    required this.secondSelectFunction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        decoration: const BoxDecoration(
            color: Colors.blue,
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      contentPadding: const EdgeInsets.all(5.0),
      content: Container(
        padding: const EdgeInsets.all(8),
        height: 150,
        width: 500,
        child: Column(
          children: [
            Text(selectQuestion),
            const SizedBox(
              height: 30,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        firstSelectFunction();
                      },
                      child: Text(firstSelectTitle)),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        secondSelectFunction();
                      },
                      child: Text(secondSelectTitle)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
