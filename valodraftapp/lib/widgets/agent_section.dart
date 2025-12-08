import 'package:flutter/material.dart';
import '../models/models.dart';
import '../draft_state.dart';

class AgentSection extends StatelessWidget {
  final DraftState draft;
  final List<ValorantAgent> agents;
  final List<ValorantAgent> teamAAgentBans;
  final List<ValorantAgent> teamBAgentBans;
  final void Function(ValorantAgent) onAgentTap;

  const AgentSection({
    super.key,
    required this.draft,
    required this.agents,
    required this.teamAAgentBans,
    required this.teamBAgentBans,
    required this.onAgentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text(
                  'Agent Draft',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _TeamAgentsColumn(team: draft.teamA)),
                const SizedBox(width: 8),
                Expanded(child: _TeamAgentsColumn(team: draft.teamB)),
              ],
            ),
            const SizedBox(height: 12),
            _BannedAgentsRow(
              teamAAgentBans: teamAAgentBans,
              teamBAgentBans: teamBAgentBans,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: agents.length,
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, childAspectRatio: .75),
              itemBuilder: (context, i) {
                final a = agents[i];

                final bannedA =
                    teamAAgentBans.any((x) => x.uuid == a.uuid);
                final bannedB =
                    teamBAgentBans.any((x) => x.uuid == a.uuid);
                final inA = draft.teamA.pickedAgents
                    .any((x) => x.uuid == a.uuid);
                final inB = draft.teamB.pickedAgents
                    .any((x) => x.uuid == a.uuid);

                final used = bannedA || bannedB || inA || inB;

                return GestureDetector(
                  onTap: () => onAgentTap(a),
                  child: AnimatedScale(
                    scale: used ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: used ? 0.6 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Stack(
                        children: [
                          Card(
                            child: Column(
                              children: [
                                Expanded(
                                  child: a.iconUrl.isNotEmpty
                                      ? Image.network(
                                          a.iconUrl,
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(Icons.person),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (used)
                            Container(
                              decoration: BoxDecoration(
                                color: bannedA
                                    ? Colors.blue.withOpacity(.55)
                                    : bannedB
                                        ? Colors.red.withOpacity(.55)
                                        : Colors.black.withOpacity(.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  bannedA || bannedB ? Icons.block : Icons.check,
                                  color: bannedA || bannedB
                                      ? Colors.white
                                      : Colors.greenAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamAgentsColumn extends StatelessWidget {
  final TeamDraft team;

  const _TeamAgentsColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (team.pickedAgents.isEmpty)
              const Text(
                'No picks yet.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            if (team.pickedAgents.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: team.pickedAgents
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
        ),
      ),
    );
  }
}

class _BannedAgentsRow extends StatelessWidget {
  final List<ValorantAgent> teamAAgentBans;
  final List<ValorantAgent> teamBAgentBans;

  const _BannedAgentsRow({
    required this.teamAAgentBans,
    required this.teamBAgentBans,
  });

  @override
  Widget build(BuildContext context) {
    final hasBans =
        teamAAgentBans.isNotEmpty || teamBAgentBans.isNotEmpty;

    if (!hasBans) {
      return const Text(
        'Banned agents: none yet.',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Banned Agents by Team',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team A',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: teamAAgentBans
                        .map(
                          (a) => Chip(
                            shape: StadiumBorder(
                              side: BorderSide(
                                  color: Colors.blueAccent.withOpacity(.7)),
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
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team B',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: teamBAgentBans
                        .map(
                          (a) => Chip(
                            shape: StadiumBorder(
                              side: BorderSide(
                                  color: Colors.redAccent.withOpacity(.7)),
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
              ),
            ),
          ],
        ),
      ],
    );
  }
}
