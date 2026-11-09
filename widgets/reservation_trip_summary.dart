import 'package:flutter/material.dart';

/// The reservation identifier followed by its airport code and flight type,
/// leaving out whichever of those two is missing.
class ReservationIdLabel extends StatelessWidget {
  const ReservationIdLabel({
    super.key,
    required this.idLabel,
    this.airportCode,
    this.flightTypeName,
    required this.style,
  });

  final String idLabel;
  final String? airportCode;
  final String? flightTypeName;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final String label = [idLabel, airportCode, flightTypeName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' | ');
    return Text(label, style: style);
  }
}

/// How many passengers, bags and pets a reservation has. A count that isn't
/// provided is left out.
class ReservationTravelerCounts extends StatelessWidget {
  const ReservationTravelerCounts({
    super.key,
    this.passengerCount,
    this.bagCount,
    this.petCount,
  });

  final int? passengerCount;
  final int? bagCount;
  final int? petCount;

  /// Whether there is any count to show.
  bool get hasCounts =>
      passengerCount != null || bagCount != null || petCount != null;

  @override
  Widget build(BuildContext context) {
    final int? passengers = passengerCount;
    final int? bags = bagCount;
    final int? pets = petCount;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (passengers != null)
          _CountItem(
            icon: Icons.airline_seat_recline_extra_outlined,
            count: passengers,
            singularLabel: 'Passenger',
          ),
        if (bags != null)
          _CountItem(
            icon: Icons.luggage_outlined,
            count: bags,
            singularLabel: 'Bag',
          ),
        if (pets != null)
          _CountItem(
            icon: Icons.pets_outlined,
            count: pets,
            singularLabel: 'Pet',
          ),
      ],
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.icon,
    required this.count,
    required this.singularLabel,
  });

  final IconData icon;
  final int count;
  final String singularLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF2292C7), size: 18),
        const SizedBox(width: 4),
        Text(
          '$count $singularLabel${count == 1 ? '' : 's'}',
          style: const TextStyle(
            color: Color(0xFF40556C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
