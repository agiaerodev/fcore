import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum AppButtonVariant { gradient, filledLight, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.leadingIcon,
    this.onPressed,
    this.variant = AppButtonVariant.gradient,
    this.height = 56,
    this.width = double.infinity,
    this.borderRadius = 16,
    this.padding,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.textStyle,
    this.iconSize = 20,
    this.isLoading = false,
  }) : assert(label != null || leadingIcon != null);

  final String? label;
  final dynamic leadingIcon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double iconSize;
  final bool isLoading;

  bool get _isIconOnly => label == null && leadingIcon != null;

  @override
  Widget build(BuildContext context) {
    final BorderRadius border = BorderRadius.circular(borderRadius);

    if (variant == AppButtonVariant.gradient) {
      return SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient:
                gradient ??
                const LinearGradient(
                  colors: [Color(0xFF2292C7), Color(0xFF26ACEB)],
                ),
            borderRadius: border,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: _resolvedPadding(),
              shape: RoundedRectangleBorder(borderRadius: border),
            ),
            child: _buildContent(_defaultForegroundColor()),
          ),
        ),
      );
    }

    if (variant == AppButtonVariant.outlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _defaultForegroundColor(),
            side: BorderSide(
              color: borderColor ?? const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            padding: _resolvedPadding(),
            shape: RoundedRectangleBorder(borderRadius: border),
          ),
          child: _buildContent(_defaultForegroundColor()),
        ),
      );
    }

    final bool isDisabled = !isLoading && onPressed == null;
    final Color bgColor = backgroundColor ?? const Color.fromARGB(255, 239, 239, 239);
    final Color fgColor = _defaultForegroundColor();
    final Color resolvedBgColor = isDisabled ? bgColor.withValues(alpha: 0.5) : bgColor;
    final Color resolvedFgColor = isDisabled ? fgColor.withValues(alpha: 0.5) : fgColor;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(resolvedBgColor),
          foregroundColor: WidgetStatePropertyAll(resolvedFgColor),
          overlayColor: WidgetStatePropertyAll(fgColor.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(_resolvedPadding()),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: border)),
        ),
        child: _buildContent(resolvedFgColor),
      ),
    );
  }

  EdgeInsetsGeometry _resolvedPadding() {
    if (padding != null) {
      return padding!;
    }

    if (_isIconOnly) {
      return EdgeInsets.zero;
    }

    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }

  Color _defaultForegroundColor() {
    if (foregroundColor != null) {
      return foregroundColor!;
    }

    switch (variant) {
      case AppButtonVariant.gradient:
        return Colors.white;
      case AppButtonVariant.filledLight:
        return const Color(0xFF245A92);
      case AppButtonVariant.outlined:
        return const Color(0xFF475569);
    }
  }

  Widget _buildContent(Color contentColor) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: contentColor,
          strokeWidth: 2.5,
        ),
      );
    }
    final TextStyle resolvedTextStyle =
        textStyle ??
        TextStyle(
          color: contentColor,
          fontSize: _isIconOnly ? iconSize : 16,
          fontWeight: FontWeight.w600,
        );

    Widget? iconWidget;
    if (leadingIcon != null) {
      if (leadingIcon is IconData) {
        iconWidget = Icon(leadingIcon, color: contentColor, size: iconSize);
      } else if (leadingIcon is FaIconData) {
        iconWidget = FaIcon(leadingIcon, color: contentColor, size: iconSize);
      }
    }

    if (_isIconOnly) {
      return iconWidget ?? const SizedBox.shrink();
    }

    if (leadingIcon == null) {
      return Text(label!, style: resolvedTextStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) iconWidget,
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label!,
            overflow: TextOverflow.ellipsis,
            style: resolvedTextStyle,
          ),
        ),
      ],
    );
  }
}