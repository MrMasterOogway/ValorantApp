import 'package:flutter/material.dart';

class PhaseBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMapPhase;
  final bool isBanPhase;
  final bool isDone;
  final bool isTeamATurn;
  final int secondsLeft;

  const PhaseBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isMapPhase,
    required this.isBanPhase,
    required this.isDone,
    required this.isTeamATurn,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    Color start;
    Color end;
    IconData icon;

    if (isDone) {
      start = Colors.grey.shade700;
      end = Colors.grey.shade900;
      icon = Icons.check_circle;
    } else if (isMapPhase) {
      start = Colors.tealAccent.shade400;
      end = Colors.teal.shade800;
      icon = Icons.map;
    } else if (isBanPhase) {
      start = Colors.redAccent.shade200;
      end = Colors.red.shade800;
      icon = Icons.block;
    } else {
      start = Colors.blueAccent.shade200;
      end = Colors.blue.shade800;
      icon = Icons.person;
    }

    final teamLabel = isDone ? 'Draft Finished' : (isTeamATurn ? 'Team A' : 'Team B');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end]),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black.withOpacity(0.2),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(teamLabel, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${secondsLeft.toString().padLeft(2, '0')}s',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
