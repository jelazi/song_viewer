import 'package:flutter/material.dart';

import '../../../services/constants.dart';

class RibbonButton extends StatefulWidget {
  const RibbonButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.isEnabled,
    this.isSelected = false,
    this.showText = true,
  });

  final String text;
  final Widget icon;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isSelected;
  final bool showText;

  @override
  State<RibbonButton> createState() => _RibbonButtonState();
}

class _RibbonButtonState extends State<RibbonButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isPressed;

    return Tooltip(
      message: widget.text,
      child: MouseRegion(
        cursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (!widget.isEnabled) return;
          setState(() => _isHovering = true);
        },
        onExit: (_) {
          setState(() {
            _isHovering = false;
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTap: () {
            if (!widget.isEnabled) return;
            widget.onPressed();
          },
          onTapDown: (_) {
            if (!widget.isEnabled) return;
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (!widget.isEnabled) return;
            setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: 30,
            padding: EdgeInsets.symmetric(
              horizontal: widget.showText ? 10 : 6,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColor.primaryColor
                  : _isHovering
                      ? AppColor.grey4Color
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: isActive
                        ? AppColor.whiteColor
                        : widget.isEnabled
                            ? AppColor.grey1Color
                            : AppColor.grey3Color,
                  ),
                  child: widget.icon,
                ),
                if (widget.showText) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? AppColor.whiteColor
                          : widget.isEnabled
                              ? AppColor.grey1Color
                              : AppColor.grey3Color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColor.grey3Color,
    );
  }
}

class ToolbarSegmentedControl<T> extends StatelessWidget {
  const ToolbarSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<ToolbarSegment<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColor.grey4Color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = item.value == selectedValue;
          final isLast = index == items.length - 1;

          return GestureDetector(
            onTap: () => onChanged(item.value),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColor.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: index == 0 ? const Radius.circular(7) : Radius.zero,
                  right: isLast ? const Radius.circular(7) : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(
                      size: 15,
                      color: isSelected ? AppColor.whiteColor : AppColor.grey2Color,
                    ),
                    child: item.icon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColor.whiteColor : AppColor.grey2Color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ToolbarSegment<T> {
  final String label;
  final Widget icon;
  final T value;

  const ToolbarSegment({
    required this.label,
    required this.icon,
    required this.value,
  });
}
