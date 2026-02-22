import 'package:flutter/material.dart';

import '../../../services/constants.dart';

class RibbonButton extends StatefulWidget {
  RibbonButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isEnabled,
    this.isSelected = false,
  });

  final String text;
  final Widget icon;
  final Function onPressed;
  final bool isEnabled;
  final bool isSelected;

  @override
  State<RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<RibbonButton> {
  bool _isHovering = false;
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.text,
      child: MouseRegion(
        cursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (event) {
          if (!widget.isEnabled) {
            return;
          }
          setState(() => _isHovering = true);
        },
        onExit: (event) {
          if (!widget.isEnabled) {
            return;
          }
          setState(() {
            _isHovering = false;
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTap: () {
            if (!widget.isEnabled) {
              return;
            }
            widget.onPressed();
          },
          onTapDown: (event) {
            if (!widget.isEnabled) {
              return;
            }
            setState(() => _isPressed = true);
          },
          onTapUp: (event) {
            if (!widget.isEnabled) {
              return;
            }
            setState(() => _isPressed = false);
          },
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isSelected || _isPressed ? AppColor.grey4Color : AppColor.whiteColor,
              border: Border.all(
                  color: _isPressed && _isHovering
                      ? AppColor.alertWarningColor
                      : _isHovering && !widget.isSelected
                          ? AppColor.primaryColor
                          : AppColor.grey3Color,
                  width: _isHovering && !widget.isSelected ? 2 : 1),
              boxShadow: _isPressed || widget.isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                Container(
                    alignment: Alignment.center,
                    width: 70,
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isEnabled ? AppColor.grey1Color : AppColor.grey3Color,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
