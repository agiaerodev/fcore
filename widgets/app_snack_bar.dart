import 'package:flutter/material.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar extends SnackBar {
  static const successDuration = Duration(seconds: 3);
  static const defaultDuration = Duration(seconds: 8);

  const AppSnackBar({
    super.key,
    required super.content,
    super.backgroundColor,
    super.behavior,
    super.closeIconColor,
    this.type = AppSnackBarType.info,
    Duration? duration,
  }) : super(
         duration:
             duration ??
             (type == AppSnackBarType.success
                 ? successDuration
                 : defaultDuration),
         showCloseIcon: true,
       );

  final AppSnackBarType type;

  @override
  SnackBar withAnimation(Animation<double> newAnimation, {Key? fallbackKey}) {
    return SnackBar(
      key: key ?? fallbackKey,
      content: _HoldableSnackBarContent(
        animation: newAnimation,
        duration: duration,
        type: type,
        accentColor: backgroundColor,
        child: content,
      ),
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: duration,
      showCloseIcon: false,
      persist: true,
      animation: newAnimation,
    );
  }
}

class _HoldableSnackBarContent extends StatefulWidget {
  const _HoldableSnackBarContent({
    required this.animation,
    required this.duration,
    required this.type,
    required this.accentColor,
    required this.child,
  });

  final Animation<double> animation;
  final Duration duration;
  final AppSnackBarType type;
  final Color? accentColor;
  final Widget child;

  @override
  State<_HoldableSnackBarContent> createState() =>
      _HoldableSnackBarContentState();
}

class _HoldableSnackBarContentState extends State<_HoldableSnackBarContent>
    with SingleTickerProviderStateMixin {
  final Set<int> _pointers = {};
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_onProgressStatus);
    widget.animation.addStatusListener(_onAnimationStatus);
    if (widget.animation.status == AnimationStatus.completed) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant _HoldableSnackBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress.duration = widget.duration;
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onAnimationStatus);
      widget.animation.addStatusListener(_onAnimationStatus);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _pointers.isEmpty) {
      _startTimer();
    } else if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _progress.stop();
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        mounted &&
        widget.animation.status == AnimationStatus.completed) {
      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
  }

  void _startTimer() {
    _progress.forward();
  }

  void _releasePointer(int pointer) {
    if (!mounted) return;
    _pointers.remove(pointer);
    if (_pointers.isEmpty &&
        widget.animation.status == AnimationStatus.completed) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onAnimationStatus);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = switch (widget.type) {
      AppSnackBarType.success => const Color(0xFF16805D),
      AppSnackBarType.error => const Color(0xFFC43844),
      AppSnackBarType.warning => const Color(0xFFA56510),
      AppSnackBarType.info => widget.accentColor ?? colors.primary,
    };
    final icon = switch (widget.type) {
      AppSnackBarType.success => Icons.check_circle_outline_rounded,
      AppSnackBarType.error => Icons.error_outline_rounded,
      AppSnackBarType.warning => Icons.warning_amber_rounded,
      AppSnackBarType.info => Icons.info_outline_rounded,
    };
    final title = switch (widget.type) {
      AppSnackBarType.success => 'Success',
      AppSnackBarType.error => 'Error',
      AppSnackBarType.warning => 'Warning',
      AppSnackBarType.info => 'Information',
    };
    final foreground =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF17212B);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!mounted) return;
        _pointers.add(event.pointer);
        _progress.stop();
      },
      onPointerUp: (event) => _releasePointer(event.pointer),
      onPointerCancel: (event) => _releasePointer(event.pointer),
      child: Container(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: foreground,
                          height: 1.4,
                        ),
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: foreground,
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => LinearProgressIndicator(
                  value: 1 - _progress.value,
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                  color: foreground,
                  backgroundColor: foreground.withValues(alpha: 0.24),
                  semanticsLabel: 'Time remaining',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
