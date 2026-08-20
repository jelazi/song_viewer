import 'package:flutter/material.dart';

class AppChord {
  static const firstChar = [" ", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "H"];

  static const midleChar = [" ", "mi", "maj"];
  static const lastChar = [" ", "4", "5", "6", "7", "9"];
}

class AppColor {
  static const defaultBackgroundColor = Color.fromARGB(255, 239, 232, 252);

  static const primaryDarkestColor = Color(0xff1D1345);
  static const primaryDarkColor = Color(0xff392485);
  static const primaryColor = Color(0xff5D3BD9);
  static const primaryLightColor = Color(0xff7D59FF);
  static const primaryLightestColor = Color.fromARGB(255, 202, 188, 255);

  static const grey1Color = Color(0xff313033);
  static const grey2Color = Color(0xff626166);
  static const grey3Color = Color(0xffC4C2CC);
  static const grey4Color = Color(0xffE9E6F2);
  static const grey5Color = Color(0xffF3F0FC);

  static const whiteColor = Colors.white;

  static const alertErrorDarkColor = Color(0xff7A1400);
  static const alertErrorColor = Color(0xffFA2900);
  static const alertErrorLightColor = Color(0xffFFD4CC);

  static const alertWarningDarkColor = Color(0xff574504);
  static const alertWarningColor = Color(0xffD6AA0A);
  static const alertWarningLightColor = Color(0xffE3D9B6);

  static const alertSuccessDarkColor = Color(0xff005C37);
  static const alertSuccessColor = Color(0xff00DB84);
  static const alertSuccessLightColor = Color(0xffBAE8D5);
}

class AppFont {
  static const h1DesktopTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 48.8, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h2DesktopTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 39, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h3DesktopTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 31.25, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h4DesktopTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 25, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h5DesktopTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 18, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const pDesktopTextStyle = TextStyle(fontFamily: 'SofiaSansCondensed', fontSize: 16, color: AppColor.grey1Color, fontWeight: FontWeight.w400);
  static const labelDesktopTextStyle = TextStyle(fontFamily: 'SofiaSansCondensed', fontSize: 19.2, color: AppColor.grey1Color, fontWeight: FontWeight.w400);

  static const h1MobileTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 24, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h2MobileTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 22, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h3MobileTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 20, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h4MobileTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 18, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const h5MobileTextStyle = TextStyle(fontFamily: 'SofiaSans', fontSize: 16, color: AppColor.grey1Color, fontWeight: FontWeight.w700);
  static const pMobileTextStyle = TextStyle(fontFamily: 'SofiaSansCondensed', fontSize: 12, color: AppColor.grey1Color, fontWeight: FontWeight.w400);
  static const labelMobileTextStyle = TextStyle(fontFamily: 'SofiaSansCondensed', fontSize: 14, color: AppColor.grey1Color, fontWeight: FontWeight.w400);
}

double fontSizeRatio = 1;
dynamic h1TextStyle;
dynamic h2TextStyle;
dynamic h3TextStyle;
dynamic h4TextStyle;
dynamic h5TextStyle;
dynamic pTextStyle;
dynamic labelTextStyle;

void resizeFontsForDesktop() {
  h1TextStyle = AppFont.h1DesktopTextStyle.copyWith(fontSize: AppFont.h1DesktopTextStyle.fontSize! * fontSizeRatio);
  h2TextStyle = AppFont.h2DesktopTextStyle.copyWith(fontSize: AppFont.h2DesktopTextStyle.fontSize! * fontSizeRatio);
  h3TextStyle = AppFont.h3DesktopTextStyle.copyWith(fontSize: AppFont.h3DesktopTextStyle.fontSize! * fontSizeRatio);
  h4TextStyle = AppFont.h4DesktopTextStyle.copyWith(fontSize: AppFont.h4DesktopTextStyle.fontSize! * fontSizeRatio);
  h5TextStyle = AppFont.h5DesktopTextStyle.copyWith(fontSize: AppFont.h5DesktopTextStyle.fontSize! * fontSizeRatio);
  pTextStyle = AppFont.pDesktopTextStyle.copyWith(fontSize: AppFont.pDesktopTextStyle.fontSize! * fontSizeRatio);
  labelTextStyle = AppFont.labelDesktopTextStyle.copyWith(fontSize: AppFont.labelDesktopTextStyle.fontSize! * fontSizeRatio);
}

void resizeFontsForMobile() {
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);

  h1TextStyle = AppFont.h1MobileTextStyle;
  h2TextStyle = AppFont.h2MobileTextStyle;
  h3TextStyle = AppFont.h3MobileTextStyle;
  h4TextStyle = AppFont.h4MobileTextStyle;
  h5TextStyle = AppFont.h5MobileTextStyle;
  pTextStyle = AppFont.pMobileTextStyle;
  labelTextStyle = AppFont.labelMobileTextStyle;
}

void resizeFontsForWeb() {
  h1TextStyle = AppFont.h1DesktopTextStyle;
  h2TextStyle = AppFont.h2DesktopTextStyle;
  h3TextStyle = AppFont.h3DesktopTextStyle;
  h4TextStyle = AppFont.h4DesktopTextStyle;
  h5TextStyle = AppFont.h5DesktopTextStyle;
  pTextStyle = AppFont.pDesktopTextStyle;
  labelTextStyle = AppFont.labelDesktopTextStyle;
}

MaterialColor getMaterialColor(Color color) {
  final int red = (color.r * 255.0).round().clamp(0, 255);
  final int green = (color.g * 255.0).round().clamp(0, 255);
  final int blue = (color.b * 255.0).round().clamp(0, 255);

  final Map<int, Color> shades = {
    50: Color.fromRGBO(red, green, blue, .1),
    100: Color.fromRGBO(red, green, blue, .2),
    200: Color.fromRGBO(red, green, blue, .3),
    300: Color.fromRGBO(red, green, blue, .4),
    400: Color.fromRGBO(red, green, blue, .5),
    500: Color.fromRGBO(red, green, blue, .6),
    600: Color.fromRGBO(red, green, blue, .7),
    700: Color.fromRGBO(red, green, blue, .8),
    800: Color.fromRGBO(red, green, blue, .9),
    900: Color.fromRGBO(red, green, blue, 1),
  };

  return MaterialColor(color.toARGB32(), shades);
}
