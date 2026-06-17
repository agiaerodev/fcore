import 'package:flutter/material.dart';
import 'package:project_airport_butler_passenger_app/core/widgets/app_button.dart';
import 'package:project_airport_butler_passenger_app/core/widgets/menu_bar_app.dart';

class NavigationAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NavigationAppBar({
    super.key,
    this.title,
    this.backgroundColor,
    this.onReportProblem,
    this.onCancelService,
    this.actions
  });

  final String? title;
  final Color? backgroundColor;
  final VoidCallback? onReportProblem;
  final VoidCallback? onCancelService;
  final List<Widget>? actions;

  // Visual size for the leading AppButton.
  final double leadingButtonSize = 45;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? const Color(0xFFF0F4F8),
      elevation: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(start: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            leadingIcon: Icons.arrow_back,
            iconSize: 24,
            onPressed: () => Navigator.maybePop(context),
            variant: AppButtonVariant.filledLight,
            backgroundColor: Colors.white,
            width: leadingButtonSize,
            height: leadingButtonSize,
          ),
        ),
      ),
      title: title != null ? Text(
        title!,
        style: const TextStyle(
          color: Color(0xFF162F48),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ) : null,
      centerTitle: false,
      actions: actions != null && actions!.isNotEmpty
        ? [
            MenuBarApp(menuItems: actions!),
            const SizedBox(width: 8),
          ]
        : null,
    );
  }
}
