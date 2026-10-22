import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../blocs/export_blocs.dart';
import '../../services/constants.dart';
import '../../services/pad_audio_engine.dart';
import '../mobile_view/widgets/settings_ui/settings_section.dart';
import '../mobile_view/widgets/settings_ui/settings_tile.dart';

const _maxFadeSeconds = 20;

String padCurveLabel(PadFadeCurve curve) {
  switch (curve) {
    case PadFadeCurve.linear:
      return 'padCurveLinear'.tr();
    case PadFadeCurve.smooth:
      return 'padCurveSmooth'.tr();
    case PadFadeCurve.gentle:
      return 'padCurveGentle'.tr();
  }
}

/// Settings section for the pad fades, shared by the phone and tablet
/// settings pages. Rebuilds with [PadBloc].
SettingsSection buildPadSettingsSection(BuildContext context) {
  final state = context.watch<PadBloc>().state;
  return SettingsSection(
    title: 'pads'.tr(),
    tiles: [
      SettingsTile(
        title: 'padFadeIn'.tr(),
        iconData: Icons.trending_up,
        value: '${state.fadeInSeconds} s',
        onPressed: (BuildContext context) => _showSecondsDialog(
          context,
          title: 'padFadeIn'.tr(),
          seconds: state.fadeInSeconds,
          onSave: (seconds) => context.read<PadBloc>().add(ChangePadFade(fadeInSeconds: seconds)),
        ),
      ),
      SettingsTile(
        title: 'padFadeOut'.tr(),
        iconData: Icons.trending_down,
        value: '${state.fadeOutSeconds} s',
        onPressed: (BuildContext context) => _showSecondsDialog(
          context,
          title: 'padFadeOut'.tr(),
          seconds: state.fadeOutSeconds,
          onSave: (seconds) => context.read<PadBloc>().add(ChangePadFade(fadeOutSeconds: seconds)),
        ),
      ),
      SettingsTile(
        title: 'padFadeCurve'.tr(),
        iconData: Icons.show_chart,
        value: padCurveLabel(state.fadeCurve),
        onPressed: (BuildContext context) => _showCurveDialog(context, state.fadeCurve),
      ),
    ],
  );
}

/// The same pad settings as a plain list for the desktop settings page.
class PadDesktopSettings extends StatelessWidget {
  const PadDesktopSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PadBloc, PadState>(
      builder: (context, state) {
        return Column(
          children: [
            _desktopTile(
              icon: Icons.trending_up,
              title: 'padFadeIn'.tr(),
              value: '${state.fadeInSeconds} s',
              onTap: () => _showSecondsDialog(
                context,
                title: 'padFadeIn'.tr(),
                seconds: state.fadeInSeconds,
                onSave: (seconds) => context.read<PadBloc>().add(ChangePadFade(fadeInSeconds: seconds)),
              ),
            ),
            _desktopTile(
              icon: Icons.trending_down,
              title: 'padFadeOut'.tr(),
              value: '${state.fadeOutSeconds} s',
              onTap: () => _showSecondsDialog(
                context,
                title: 'padFadeOut'.tr(),
                seconds: state.fadeOutSeconds,
                onSave: (seconds) => context.read<PadBloc>().add(ChangePadFade(fadeOutSeconds: seconds)),
              ),
            ),
            _desktopTile(
              icon: Icons.show_chart,
              title: 'padFadeCurve'.tr(),
              value: padCurveLabel(state.fadeCurve),
              onTap: () => _showCurveDialog(context, state.fadeCurve),
            ),
          ],
        );
      },
    );
  }

  Widget _desktopTile({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: AppColor.grey2Color),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Text(value, style: const TextStyle(fontSize: 13, color: AppColor.primaryColor, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

void _showSecondsDialog(BuildContext context, {required String title, required int seconds, required ValueChanged<int> onSave}) {
  var value = seconds;
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColor.primaryColor)),
            Slider(
              value: value.toDouble(),
              max: _maxFadeSeconds.toDouble(),
              divisions: _maxFadeSeconds,
              onChanged: (newValue) => setState(() => value = newValue.round()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              onSave(value);
              Navigator.pop(dialogContext);
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    ),
  );
}

void _showCurveDialog(BuildContext context, PadFadeCurve current) {
  showDialog(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('padFadeCurve'.tr()),
      children: [
        for (final curve in PadFadeCurve.values)
          ListTile(
            leading: Icon(curve == current ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppColor.primaryColor),
            title: Text(padCurveLabel(curve)),
            subtitle: SizedBox(height: 28, child: CustomPaint(painter: _CurvePainter(curve))),
            onTap: () {
              context.read<PadBloc>().add(ChangePadFade(curve: curve));
              Navigator.pop(dialogContext);
            },
          ),
      ],
    ),
  );
}

/// Draws the fade-in shape so the choice is visible, not just named.
class _CurvePainter extends CustomPainter {
  final PadFadeCurve curve;

  _CurvePainter(this.curve);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(t * size.width * 0.6, size.height * (1 - curve.fadeIn(t)));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColor.primaryLightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) => oldDelegate.curve != curve;
}
