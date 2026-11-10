import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/avatar_url_helper.dart';
import '../utils/concierge_role_label.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/reservation_trip_summary.dart';
import '../widgets/status_tag.dart';

class ReservationData {
  const ReservationData({
    required this.bookingId,
    required this.routeName,
    this.airportCode,
    this.flightTypeName,
    this.passengerCount,
    this.bagCount,
    this.petCount,
    this.startDate,
    required this.agentName,
    required this.agentRole,
    this.additionalAgentNames = const [],
    this.agentImageUrl,
    required this.statusLabel,
    required this.statusColor,
    this.statusDescription,
  });

  final int bookingId;
  final String routeName;
  final String? airportCode;
  final String? flightTypeName;
  final int? passengerCount;
  final int? bagCount;
  final int? petCount;
  final DateTime? startDate;
  final String agentName;
  final String agentRole;
  final List<String> additionalAgentNames;
  final String? agentImageUrl;
  final String statusLabel;
  final Color statusColor;
  final String? statusDescription;

  String get formattedDateTime {
    final date = startDate;
    if (date == null) return '--';
    return '${DateFormat('MMM, dd yyyy').format(date)} - ${DateFormat('hh:mm a').format(date)}';
  }
}

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onChatTap,
    required this.onCallTap,
    required this.screen,
    this.onReturn,
  });

  final ReservationData reservation;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;
  final Widget Function({required int bookingId}) screen;
  final Future<void> Function()? onReturn;

  @override
  Widget build(BuildContext context) {
    final String avatarUrl = resolveAvatarUrl(
      displayName: reservation.agentName, 
      imageUrl: reservation.agentImageUrl
    );
    final travelerCounts = ReservationTravelerCounts(
      passengerCount: reservation.passengerCount,
      bagCount: reservation.bagCount,
      petCount: reservation.petCount,
    );

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screen(bookingId: reservation.bookingId),
          ),
        );
        await onReturn?.call();
      },
      child: AppCard(
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F162F48),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
        slot: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ReservationIdLabel(
                    idLabel: 'ID ${reservation.bookingId}',
                    airportCode: reservation.airportCode,
                    flightTypeName: reservation.flightTypeName,
                    style: const TextStyle(
                      color: Color(0xFF2093CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusTag(
                  label: reservation.statusLabel,
                  color: reservation.statusColor,
                  description: reservation.statusDescription,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reservation.routeName,
              style: const TextStyle(
                color: Color(0xFF162F48),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reservation.formattedDateTime,
              style: const TextStyle(
                color: Color(0xFF718499),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (travelerCounts.hasCounts) ...[
              const SizedBox(height: 6),
              travelerCounts,
            ],
            const SizedBox(height: 8),
            if (reservation.agentName.trim().isNotEmpty &&
                reservation.agentRole.trim().isNotEmpty) ...[
              const Divider(color: Color(0xFFC7D6E4), thickness: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reservation.agentName,
                                style: const TextStyle(
                                  color: Color(0xFF1D3553),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              color: Color(0xFF2292C7),
                              size: 18,
                              semanticLabel: 'Primary Concierge',
                            ),
                          ],
                        ),
                        Text(
                          reservation.agentRole,
                          style: const TextStyle(
                            color: Color(0xFF667D97),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        for (var index = 0;
                            index < reservation.additionalAgentNames.length;
                            index++) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${conciergeRoleLabel(index + 1)}: ${reservation.additionalAgentNames[index]}',
                            style: const TextStyle(
                              color: Color(0xFF667D97),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  /*quickActionButton(
                    icon: Icons.chat_bubble_outline,
                    onTap: onChatTap,
                  ),*/
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget quickActionButton ({
    required IconData icon,
    required VoidCallback onTap
  }) {
    return AppButton(
      leadingIcon: icon,
      variant: AppButtonVariant.filledLight,
      backgroundColor: Color(0xFFB9DEF6),
      iconSize: 26,
      width: 48,
      height: 48,
      onPressed: onTap,
    );
  }
}
