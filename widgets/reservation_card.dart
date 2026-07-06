import 'package:flutter/material.dart';
import 'package:project_airport_butler_passenger_app/core/utils/avatar_url_helper.dart';
import 'package:project_airport_butler_passenger_app/modules/reservations/models/reservation_model.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class ReservationData {
  const ReservationData({
    required this.bookingId,
    required this.routeCode,
    required this.routeName,
    required this.dateTimeText,
    required this.agentName,
    required this.agentRole,
    this.agentImageUrl,
    required this.status,
  });

  final int bookingId;
  final String routeCode;
  final String routeName;
  final String dateTimeText;
  final String agentName;
  final String agentRole;
  final String? agentImageUrl;
  final BookingStatus status;
}

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onChatTap,
    required this.onCallTap,
    required this.screen
  });

  final ReservationData reservation;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;
  final Widget Function({required int bookingId}) screen;

  @override
  Widget build(BuildContext context) {
    final String avatarUrl = resolveAvatarUrl(
      displayName: reservation.agentName, 
      imageUrl: reservation.agentImageUrl
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screen(bookingId: reservation.bookingId),
          ),
        );
      },
      child: AppCard(
        slot: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.routeCode,
                    style: const TextStyle(
                      color: Color(0xFF2093CF),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusTag(status: reservation.status),
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
              reservation.dateTimeText,
              style: const TextStyle(
                color: Color(0xFF718499),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
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
                      Text(
                        reservation.agentName,
                        style: const TextStyle(
                          color: Color(0xFF1D3553),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        reservation.agentRole,
                        style: const TextStyle(
                          color: Color(0xFF667D97),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                quickActionButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: onChatTap,
                ),
                const SizedBox(width: 10),
                quickActionButton(
                  icon: Icons.call_outlined, 
                  onTap: onCallTap
                ),
              ],
            ),
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

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.flutterColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
