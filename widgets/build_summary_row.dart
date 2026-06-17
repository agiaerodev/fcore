import 'package:flutter/material.dart';

class BuildSummaryRow extends StatelessWidget {
  const BuildSummaryRow({
    super.key,
    required this.label,
    required this.value, 
    this.color = const Color(0xFF162F48),
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF718499),
              fontSize: 14,
              fontWeight: FontWeight.w500
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600
          ),
        )
      ],
    );
  }
}