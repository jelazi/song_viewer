import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../services/constants.dart';
import 'my_progress_indicator.dart';

enum TypeNotification {
  error,
  warning,
  success,
  info,
  chat,
}

double myToastWidth = 350;

class MyToast {
  static CancelFunc showText({
    required String text,
    required TypeNotification typeNotification,
    String typeNotificationString = 'Warning',
    String? errorCode,
    double? usableTime,
    Function? openChatDialog,
    bool openChatDialogOnClose = false,
  }) {
    Color color = AppColor.primaryColor;
    Color backgroundColor = AppColor.primaryLightestColor;
    Color fontColor = AppColor.primaryDarkestColor;
    switch (typeNotification) {
      case TypeNotification.warning:
        typeNotificationString = '${'warning'.tr()}: ';
        color = AppColor.alertWarningColor;
        backgroundColor = AppColor.alertWarningLightColor;
        fontColor = AppColor.alertWarningDarkColor;
        break;
      case TypeNotification.error:
        typeNotificationString = 'error'.tr();
        color = AppColor.alertErrorColor;
        backgroundColor = AppColor.alertErrorLightColor;
        fontColor = AppColor.alertErrorDarkColor;
        break;
      case TypeNotification.success:
        typeNotificationString = '${'success'.tr()}: ';
        color = AppColor.alertSuccessColor;
        backgroundColor = AppColor.alertSuccessLightColor;
        fontColor = AppColor.alertSuccessDarkColor;
        break;
      case TypeNotification.info:
        typeNotificationString = '${'info'.tr()}: ';
        color = AppColor.primaryColor;
        backgroundColor = AppColor.primaryLightestColor;
        fontColor = AppColor.primaryDarkestColor;
        break;
      case TypeNotification.chat:
        typeNotificationString = '${'chat'.tr()}: ';
        color = AppColor.primaryColor;
        backgroundColor = AppColor.primaryLightestColor;
        fontColor = AppColor.primaryDarkestColor;
    }

    late CancelFunc cancel;
    cancel = BotToast.showCustomText(
      backButtonBehavior: BackButtonBehavior.close,
      duration: const Duration(seconds: 10),
      onClose: () {
        if (typeNotification == TypeNotification.chat && openChatDialog != null && openChatDialogOnClose) {
          openChatDialog();
        }
      },
      toastBuilder: (_) {
        // Define text style for toast
        final pTextStyle = const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        );

        return MouseRegion(
          cursor: typeNotification == TypeNotification.chat ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: () {
              openChatDialogOnClose = true;
              cancel();
            },
            child: Container(
              margin: const EdgeInsets.all(15),
              width: myToastWidth,
              height: 100,
              decoration: BoxDecoration(
                color: AppColor.whiteColor,
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                padding: const EdgeInsets.only(left: 12, top: 5),
                                width: myToastWidth - 50,
                                height: 58,
                                child: SingleChildScrollView(
                                  child: RichText(
                                    text: TextSpan(
                                      style: pTextStyle.copyWith(fontWeight: FontWeight.w800, color: fontColor),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: typeNotificationString,
                                        ),
                                        TextSpan(text: text, style: pTextStyle.copyWith(color: fontColor)),
                                      ],
                                    ),
                                  ),
                                )),
                            GestureDetector(
                              onTap: () {
                                cancel();
                              },
                              child: Container(
                                width: 30,
                                height: 25,
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(border: Border.all(color: AppColor.primaryColor), borderRadius: BorderRadius.circular(4)),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColor.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(errorCode ?? '',
                            style: pTextStyle.copyWith(
                              color: color,
                              fontSize: 12.0,
                            ))
                      ],
                    ),
                  ),
                  Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: SizedBox(
                          width: 350,
                          child: MyProgressIndicator(
                            usableTime: usableTime,
                            color: color,
                            backgroundColor: backgroundColor,
                          ))),
                ],
              ),
            ),
          ),
        );
      },
    );
    return cancel;
  }
}
