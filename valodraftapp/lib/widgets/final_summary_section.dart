import 'package:flutter/material.dart';
import '../models/models.dart';
import '../draft_state.dart';

class FinalSummarySection extends StatelessWidget {
  final ValorantMap? finalMap;
  final TeamDraft teamA;
  final TeamDraft teamB;
  final List<ValorantMap> teamAMapBans;
  final List<ValorantMap> teamBMapBans;
  final List<ValorantAgent> teamAAgentBans;
  final List<ValorantAgent> teamBAgentBans;

  const FinalSummarySection({
    super.key,
    required this.finalMap,
    required this.teamA,
    required this.teamB,
    required this.teamAMapBans,
    required this.teamBMapBans,
    required this.teamAAgentBans,
    required this.teamBAgentBans,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  'Final Draft',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamAgentsBlock(
                        title: teamA.name,
                        agents: teamA.pickedAgents,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FinalMapBlock(map: finalMap),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TeamAgentsBlock(
                        title: teamB.name,
                        agents: teamB.pickedAgents,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banned Maps',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BannedMapsColumn(
                        title: 'Team A',
                        maps: teamAMapBans,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Expanded(
                      child: _BannedMapsColumn(
                        title: 'Team B',
                        maps: teamBMapBans,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banned Agents',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BannedAgentsColumn(
                        title: 'Team A',
                        agents: teamAAgentBans,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Expanded(
                      child: _BannedAgentsColumn(
                        title: 'Team B',
                        agents: teamBAgentBans,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalMapBlock extends StatelessWidget {
  final ValorantMap? map;

  const _FinalMapBlock({required this.map});

  @override
  Widget build(BuildContext context) {
    final title = map?.displayName ?? 'No map selected';

    return Column(
      children: [
        const Text(
          'Chosen Map',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (map == null)
          const Text(
            'No map selected',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          )
        else
          Column(
            children: [
              if (map!.splash.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    map!.splash,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
      ],
    );
  }
}

class _TeamAgentsBlock extends StatelessWidget {
  final String title;
  final List<ValorantAgent> agents;
  final Color color;

  const _TeamAgentsBlock({
    required this.title,
    required this.agents,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 6),
        if (agents.isEmpty)
          const Text(
            'No agents selected.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: agents
                .map(
                  (a) => Chip(
                    avatar: a.iconUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(a.iconUrl),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person, size: 14),
                          ),
                    label: Text(
                      a.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _BannedMapsColumn extends StatelessWidget {
  final String title;
  final List<ValorantMap> maps;
  final Color color;

  const _BannedMapsColumn({
    required this.title,
    required this.maps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (maps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          const Text(
            'No bans.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Wrap(
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
                  border: Border.all(color: color.withOpacity(0.9), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: img.isNotEmpty
                      ? Image.network(
                          img,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.map, size: 18),
                        ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BannedAgentsColumn extends StatelessWidget {
  final String title;
  final List<ValorantAgent> agents;
  final Color color;

  const _BannedAgentsColumn({
    required this.title,
    required this.agents,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          const Text(
            'No bans.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: agents
              .map(
                (a) => Chip(
                  shape: StadiumBorder(
                    side: BorderSide(color: color.withOpacity(0.8)),
                  ),
                  avatar: a.iconUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(a.iconUrl),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person, size: 14),
                        ),
                  label: Text(
                    a.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
