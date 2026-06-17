import 'package:flutter/material.dart';
import 'package:project_airport_butler_passenger_app/core/widgets/app_button.dart';

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({ super.key, required this.menuItems });

  final List<Widget> menuItems;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-16, 0),
      style: MenuStyle(
        alignment: AlignmentDirectional.bottomEnd,
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(6),
        minimumSize: const WidgetStatePropertyAll(Size(176, 0)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      menuChildren: menuItems,
      builder: (context, controller, child) {
        return AppButton(
          leadingIcon: Icons.more_vert,
          iconSize: 24,
          variant: AppButtonVariant.filledLight,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF162F48),
          width: 45,
          height: 45,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
              return;
            }
            controller.open();
          },
        );
      },
    );
  }
}