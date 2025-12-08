import 'package:flutter/material.dart';
import '../models/models.dart';

class MapSection extends StatelessWidget {
  final List<ValorantMap> maps;
  final List<ValorantMap> teamAMapBans;
  final List<ValorantMap> teamBMapBans;
  final int teamAMapBansCount;
  final int teamBMapBansCount;
  final ValorantMap? finalSelectedMap;
  final void Function(ValorantMap) onMapTap;

  const MapSection({
    super.key,
    required this.maps,
    required this.teamAMapBans,
    required this.teamBMapBans,
    required this.teamAMapBansCount,
    required this.teamBMapBansCount,
    required this.finalSelectedMap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final mapTitle =
        finalSelectedMap != null ? finalSelectedMap!.displayName : 'Not selected';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.map),
                SizedBox(width: 8),
                Text(
                  'Map Draft',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team A Bans',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildMapBanStrip(teamAMapBans, Colors.blueAccent),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Chosen Map',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (finalSelectedMap == null)
                        const Text(
                          'Not selected',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      else
                        Column(
                          children: [
                            if (finalSelectedMap!.splash.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  finalSelectedMap!.splash,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              mapTitle,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Team B Bans',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildMapBanStrip(teamBMapBans, Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Maps to choose from',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: maps.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, childAspectRatio: .9),
              itemBuilder: (context, i) {
                final m = maps[i];
                final bannedA =
                    teamAMapBans.any((x) => x.uuid == m.uuid);
                final bannedB =
                    teamBMapBans.any((x) => x.uuid == m.uuid);
                final selected =
                    finalSelectedMap != null && finalSelectedMap!.uuid == m.uuid;

                return GestureDetector(
                  onTap: () => onMapTap(m),
                  child: Stack(
                    children: [
                      Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: (m.displayIcon.isNotEmpty
                                      ? m.displayIcon
                                      : m.splash)
                                  .isNotEmpty
                                  ? Image.network(
                                      m.displayIcon.isNotEmpty
                                          ? m.displayIcon
                                          : m.splash,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.map),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (selected || bannedA || bannedB)
                        Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.amber.withOpacity(0.45)
                                : bannedA
                                    ? Colors.blue.withOpacity(0.45)
                                    : Colors.red.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBanStrip(List<ValorantMap> maps, Color tint) {
    if (maps.isEmpty) {
      return const Text(
        'No bans yet',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: maps.map((m) {
        final img = m.displayIcon.isNotEmpty ? m.displayIcon : m.splash;
        return Tooltip(
          message: m.displayName,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tint.withOpacity(0.8), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: img.isNotEmpty
                  ? Image.network(
                      img,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.map, size: 18),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
