import 'package:flutter/material.dart';

class AppSnackBar extends SnackBar {
  const AppSnackBar({
    super.key,
    required super.content,
    super.backgroundColor,
    super.behavior,
    super.closeIconColor,
  }) : super(duration: const Duration(seconds: 8), showCloseIcon: true);

  @override
  SnackBar withAnimation(Animation<double> newAnimation, {Key? fallbackKey}) {
    return SnackBar(
      key: key ?? fallbackKey,
      content: _HoldableSnackBarContent(
        animation: newAnimation,
        progressColor: closeIconColor,
        child: content,
      ),
      backgroundColor: backgroundColor,
      behavior: behavior,
      closeIconColor: closeIconColor,
      duration: duration,
      showCloseIcon: showCloseIcon,
      persist: true,
      animation: newAnimation,
    );
  }
}

class _HoldableSnackBarContent extends StatefulWidget {
  const _HoldableSnackBarContent({
    required this.animation,
    required this.progressColor,
    required this.child,
  });

  final Animation<double> animation;
  final Color? progressColor;
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
      duration: const Duration(seconds: 8),
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
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (!mounted) return;
        _pointers.add(event.pointer);
        _progress.stop();
      },
      onPointerUp: (event) => _releasePointer(event.pointer),
      onPointerCancel: (event) => _releasePointer(event.pointer),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.child,
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => LinearProgressIndicator(
              value: 1 - _progress.value,
              minHeight: 3,
              color:
                  widget.progressColor ??
                  Theme.of(context).colorScheme.onInverseSurface,
              backgroundColor:
                  (widget.progressColor ??
                          Theme.of(context).colorScheme.onInverseSurface)
                      .withValues(alpha: 0.25),
              semanticsLabel: 'Time remaining',
            ),
          ),
        ],
      ),
    );
  }
}
