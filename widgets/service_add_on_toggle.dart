import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/app_button.dart';
import '../widgets/app_switch.dart';

class ServiceAddOnToggle extends StatelessWidget {
  const ServiceAddOnToggle({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    this.price = '--',
    required this.isActive,
    this.onChange,
    this.requiresQuantity = false,
    this.quantity = 1,
    this.onQuantityChanged,
  });

  final FaIconData? icon;
  final String title;
  final String subtitle;
  final String price;
  final bool isActive;
  final ValueChanged<bool>? onChange;

  final bool requiresQuantity;
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: FaIcon(icon, color: Color(0xFF2292C7)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF162F48),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF40556C),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '\$${(double.tryParse(price) ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF162F48),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSwitch(value: isActive, onChanged: onChange),
            ],
          ),
        ),
        if (requiresQuantity && isActive) ...[
          const SizedBox(height: 16),
          _QuantitySelector(
            label: 'Quantity',
            unitPrice: double.tryParse(price) ?? 0.0,
            quantity: quantity,
            onChanged: onQuantityChanged,
          ),
        ],
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.label,
    required this.unitPrice,
    required this.quantity,
    this.onChanged,
  });

  final String label;
  final double unitPrice;
  final int quantity;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC6D2DE)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${unitPrice * quantity} each',
                  style: const TextStyle(
                    color: Color(0xFF162F48),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              AppButton(
                leadingIcon: Icons.remove_circle_outline,
                foregroundColor: quantity == 1 ? Color.fromARGB(255, 171, 171, 171) : Color(0xFF40556C),
                width: 30,
                height: 30,
                variant: AppButtonVariant.filledLight,
                padding: EdgeInsets.all(0),
                iconSize: 30,
                backgroundColor: Colors.transparent,
                onPressed: () {
                  if (quantity > 1) {
                    onChanged?.call(quantity - 1);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Color(0xFF162F48),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppButton(
                leadingIcon: Icons.add_circle_outline,
                foregroundColor: Color(0xFF40556C),
                width: 30,
                height: 30,
                variant: AppButtonVariant.filledLight,
                padding: EdgeInsets.all(0),
                iconSize: 30,
                backgroundColor: Colors.transparent,
                onPressed: () {
                  onChanged?.call(quantity + 1);
                },
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          left: 12,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF40556C),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
