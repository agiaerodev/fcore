import 'package:flutter/material.dart';
import '../widgets/app_switch.dart';

class ServiceAddOnToggle extends StatelessWidget {
  const ServiceAddOnToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isActive,
    this.onChange
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool isActive;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Icon(icon, color: Color(0xFF2292C7)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Color(0xFF162F48),
                  fontSize: 16,
                  fontWeight: FontWeight.w500
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Color(0xFF40556C),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              )
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Text(
            price,
            style: TextStyle(
              color: Color(0xFF162F48),
              fontSize: 14,
              fontWeight: FontWeight.w700
            ),
          ),
        ),
        AppSwitch(
          value: isActive, 
          onChanged: onChange
        ),
      ],
      ),
    );
  }
}