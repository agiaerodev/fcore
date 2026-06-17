import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({ 
    super.key, 
    required this.slot,
    this.isSelected = false,
  });

  final Widget slot;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
          ? const BorderSide(color: Color(0xFFC4ECFF), width: 4)
          : BorderSide.none,
      ),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: slot,
      )
    );
  }
}