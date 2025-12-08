import 'package:flutter/material.dart';
import 'draft_state.dart';
import 'models.dart';
import 'valorant_api.dart';

void main() {
  runApp(const ValorantDraftApp());
}

class ValorantDraftApp extends StatelessWidget {
  const ValorantDraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VALORANT Draft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DraftScreen(),
    );
  }
}

enum DraftPhase {
  mapBanTeamA,
  mapBanTeamB,
  agentBan1TeamA,
  agentBan1TeamB,
  agentPick1TeamA,
  agentPick1TeamB,
  agentBan2TeamA,
  agentBan2TeamB,
  agentPick2TeamA,
  agentPick2TeamB,
  done,
}

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final _api = ValorantApi();
  final _draft = DraftState();
  late Future<void> _loadFuture;
  List<ValorantAgent> _agents = [];
  List<ValorantMap> _maps = [];
  DraftPhase _phase = DraftPhase.mapBanTeamA;
  int _teamAMapBans = 0;
  int _teamBMapBans = 0;
  ValorantMap? _finalSelectedMap;
  int _teamAFirstAgentBans = 0;
  int _teamBFirstAgentBans = 0;
  int _teamAFirstAgentPicks = 0;
  int _teamBFirstAgentPicks = 0;
  int _teamASecondAgentBans = 0;
  int _teamBSecondAgentBans = 0;
  int _teamASecondAgentPicks = 0;
  int _teamBSecondAgentPicks = 0;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final agents = await _api.fetchAgents();
    final maps = await _api.fetchMaps();
    setState(() {
      _agents = agents;
      _maps = maps;
    });
  }

  bool get _isMapPhase =>
      _phase == DraftPhase.mapBanTeamA || _phase == DraftPhase.mapBanTeamB;

  bool get _isTeamATurn {
    switch (_phase) {
      case DraftPhase.mapBanTeamA:
      case DraftPhase.agentBan1TeamA:
      case DraftPhase.agentPick1TeamA:
      case DraftPhase.agentBan2TeamA:
      case DraftPhase.agentPick2TeamA:
        return true;
      case DraftPhase.mapBanTeamB:
      case DraftPhase.agentBan1TeamB:
      case DraftPhase.agentPick1TeamB:
      case DraftPhase.agentBan2TeamB:
      case DraftPhase.agentPick2TeamB:
      case DraftPhase.done:
        return false;
    }
  }

  String get _phaseTitle {
    switch (_phase) {
      case DraftPhase.mapBanTeamA:
      case DraftPhase.mapBanTeamB:
        return 'Map Ban Phase';
      case DraftPhase.agentBan1TeamA:
      case DraftPhase.agentBan1TeamB:
      case DraftPhase.agentBan2TeamA:
      case DraftPhase.agentBan2TeamB:
        return 'Agent Ban Phase';
      case DraftPhase.agentPick1TeamA:
      case DraftPhase.agentPick1TeamB:
      case DraftPhase.agentPick2TeamA:
      case DraftPhase.agentPick2TeamB:
        return 'Agent Pick Phase';
      case DraftPhase.done:
        return 'Draft Completed';
    }
  }

  String get _phaseSubtitle {
    if (_phase == DraftPhase.done) {
      final mapName = _finalSelectedMap?.displayName ?? 'No map selected';
      return 'Draft is complete. Final map: $mapName';
    }

    final teamLabel = _isTeamATurn ? 'Team A' : 'Team B';

    switch (_phase) {
      case DraftPhase.mapBanTeamA:
        return '$teamLabel: Tap 3 maps to ban.';
      case DraftPhase.mapBanTeamB:
        return '$teamLabel: Tap 3 maps to ban.';

      case DraftPhase.agentBan1TeamA:
      case DraftPhase.agentBan1TeamB:
        return '$teamLabel: Ban 3 agents. (First ban phase)';

      case DraftPhase.agentPick1TeamA:
      case DraftPhase.agentPick1TeamB:
        return '$teamLabel: Pick 3 agents. (First pick phase)';

      case DraftPhase.agentBan2TeamA:
      case DraftPhase.agentBan2TeamB:
        return '$teamLabel: Ban 2 agents. (Second ban phase)';

      case DraftPhase.agentPick2TeamA:
      case DraftPhase.agentPick2TeamB:
        return '$teamLabel: Pick 2 agents. (Second pick phase)';

      case DraftPhase.done:
        return '';
    }
  }

  void _onMapTap(ValorantMap map) {
    if (!_isMapPhase) {
      _showSnack('Map phase is finished. Final map: '
          '${_finalSelectedMap?.displayName ?? 'N/A'}.');
      return;
    }

    final bool isTeamA = _phase == DraftPhase.mapBanTeamA;

    if (isTeamA && _teamAMapBans >= 3) {
      _showSnack('Team A has already banned 3 maps.');
      return;
    }
    if (!isTeamA && _teamBMapBans >= 3) {
      _showSnack('Team B has already banned 3 maps.');
      return;
    }

    final ok = _draft.banMap(map);
    if (!ok) {
      _showSnack('Cannot ban this map (already banned).');
      return;
    }

    if (isTeamA) {
      _teamAMapBans++;
      if (_teamAMapBans >= 3) {
        _phase = DraftPhase.mapBanTeamB;
      }
    } else {
      _teamBMapBans++;
    }

    if (_teamAMapBans >= 3 && _teamBMapBans >= 3) {
      _selectFinalMapFromRemaining();
      _phase = DraftPhase.agentBan1TeamA;
    }

    setState(() {});
  }

  void _onAgentTap(ValorantAgent agent) {
    if (_isMapPhase) {
      _showSnack('Finish map bans first (top section).');
      return;
    }

    switch (_phase) {
      case DraftPhase.agentBan1TeamA:
        _handleAgentBan(agent, isTeamA: true, phase: 1);
        break;
      case DraftPhase.agentBan1TeamB:
        _handleAgentBan(agent, isTeamA: false, phase: 1);
        break;
      case DraftPhase.agentPick1TeamA:
        _handleAgentPick(agent, isTeamA: true, phase: 1);
        break;
      case DraftPhase.agentPick1TeamB:
        _handleAgentPick(agent, isTeamA: false, phase: 1);
        break;
      case DraftPhase.agentBan2TeamA:
        _handleAgentBan(agent, isTeamA: true, phase: 2);
        break;
      case DraftPhase.agentBan2TeamB:
        _handleAgentBan(agent, isTeamA: false, phase: 2);
        break;
      case DraftPhase.agentPick2TeamA:
        _handleAgentPick(agent, isTeamA: true, phase: 2);
        break;
      case DraftPhase.agentPick2TeamB:
        _handleAgentPick(agent, isTeamA: false, phase: 2);
        break;
      case DraftPhase.mapBanTeamA:
      case DraftPhase.mapBanTeamB:
        _showSnack('You are still in map ban phase.');
        break;
      case DraftPhase.done:
        _showSnack('Draft is complete.');
        break;
    }
  }

  void _handleAgentBan(ValorantAgent agent,
      {required bool isTeamA, required int phase}) {
    if (phase == 1) {
      if (isTeamA && _teamAFirstAgentBans >= 3) {
        _showSnack('Team A has already banned 3 agents.');
        return;
      }
      if (!isTeamA && _teamBFirstAgentBans >= 3) {
        _showSnack('Team B has already banned 3 agents.');
        return;
      }
    } else {
      if (isTeamA && _teamASecondAgentBans >= 2) {
        _showSnack('Team A has already banned 2 agents (second phase).');
        return;
      }
      if (!isTeamA && _teamBSecondAgentBans >= 2) {
        _showSnack('Team B has already banned 2 agents (second phase).');
        return;
      }
    }

    final ok = _draft.banAgent(agent);
    if (!ok) {
      _showSnack('Cannot ban this agent (already banned or picked).');
      return;
    }

    if (phase == 1) {
      if (isTeamA) {
        _teamAFirstAgentBans++;
        if (_teamAFirstAgentBans >= 3) {
          _phase = DraftPhase.agentBan1TeamB;
        }
      } else {
        _teamBFirstAgentBans++;
        if (_teamBFirstAgentBans >= 3) {
          _phase = DraftPhase.agentPick1TeamA;
        }
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentBans++;
        if (_teamASecondAgentBans >= 2) {
          _phase = DraftPhase.agentBan2TeamB;
        }
      } else {
        _teamBSecondAgentBans++;
        if (_teamBSecondAgentBans >= 2) {
          _phase = DraftPhase.agentPick2TeamA;
        }
      }
    }

    setState(() {});
  }

  void _handleAgentPick(ValorantAgent agent,
      {required bool isTeamA, required int phase}) {
    final team = isTeamA ? _draft.teamA : _draft.teamB;

    if (phase == 1) {
      if (isTeamA && _teamAFirstAgentPicks >= 3) {
        _showSnack('Team A has already picked 3 agents.');
        return;
      }
      if (!isTeamA && _teamBFirstAgentPicks >= 3) {
        _showSnack('Team B has already picked 3 agents.');
        return;
      }
    } else {
      if (isTeamA && _teamASecondAgentPicks >= 2) {
        _showSnack('Team A has already picked 2 agents (second phase).');
        return;
      }
      if (!isTeamA && _teamBSecondAgentPicks >= 2) {
        _showSnack('Team B has already picked 2 agents (second phase).');
        return;
      }
    }

    final ok = _draft.pickAgent(agent, team);
    if (!ok) {
      _showSnack('Cannot pick this agent (already banned or picked).');
      return;
    }

    if (phase == 1) {
      if (isTeamA) {
        _teamAFirstAgentPicks++;
        if (_teamAFirstAgentPicks >= 3) {
          _phase = DraftPhase.agentPick1TeamB;
        }
      } else {
        _teamBFirstAgentPicks++;
        if (_teamBFirstAgentPicks >= 3) {
          _phase = DraftPhase.agentBan2TeamA;
        }
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentPicks++;
        if (_teamASecondAgentPicks >= 2) {
          _phase = DraftPhase.agentPick2TeamB;
        }
      } else {
        _teamBSecondAgentPicks++;
        if (_teamBSecondAgentPicks >= 2) {
          _phase = DraftPhase.done;
        }
      }
    }

    setState(() {});
  }

  void _selectFinalMapFromRemaining() {
    final bannedIds = _draft.bannedMaps.map((m) => m.uuid).toSet();
    final remaining = _maps.where((m) => !bannedIds.contains(m.uuid)).toList();
    if (remaining.isEmpty) {
      _finalSelectedMap = null;
      return;
    }
    remaining.shuffle();
    _finalSelectedMap = remaining.first;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VALORANT Draft / Ban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset draft',
            onPressed: () {
              setState(() {
                _draft.reset();
                _phase = DraftPhase.mapBanTeamA;
                _teamAMapBans = 0;
                _teamBMapBans = 0;
                _finalSelectedMap = null;
                _teamAFirstAgentBans = 0;
                _teamBFirstAgentBans = 0;
                _teamAFirstAgentPicks = 0;
                _teamBFirstAgentPicks = 0;
                _teamASecondAgentBans = 0;
                _teamBSecondAgentBans = 0;
                _teamASecondAgentPicks = 0;
                _teamBSecondAgentPicks = 0;
                _loadFuture = _loadData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildPhaseBanner(),
                const SizedBox(height: 12),
                _buildMapSection(),
                const SizedBox(height: 16),
                _buildAgentSection(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhaseBanner() {
    Color start;
    Color end;
    IconData icon;

    if (_phase == DraftPhase.done) {
      start = Colors.grey.shade700;
      end = Colors.grey.shade900;
      icon = Icons.check_circle;
    } else if (_isMapPhase) {
      start = Colors.tealAccent.shade400;
      end = Colors.teal.shade800;
      icon = Icons.map;
    } else {
      // Agent phases
      if (_phase == DraftPhase.agentBan1TeamA ||
          _phase == DraftPhase.agentBan1TeamB ||
          _phase == DraftPhase.agentBan2TeamA ||
          _phase == DraftPhase.agentBan2TeamB) {
        start = Colors.redAccent.shade200;
        end = Colors.red.shade900;
        icon = Icons.block;
      } else {
        start = Colors.blueAccent.shade200;
        end = Colors.blue.shade900;
        icon = Icons.person;
      }
    }

    final teamLabel = _phase == DraftPhase.done
        ? 'Draft Finished'
        : (_isTeamATurn ? 'Team A Turn' : 'Team B Turn');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: end.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Text(
                  _phaseTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phaseSubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              teamLabel,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final mapTitle = _finalSelectedMap != null
        ? _finalSelectedMap!.displayName
        : 'Not selected yet';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map),
                const SizedBox(width: 8),
                const Text(
                  'Map Draft',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    'A bans: $_teamAMapBans / 3',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(
                    'B bans: $_teamBMapBans / 3',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Final map: $mapTitle',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              itemCount: _maps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final map = _maps[index];
                final bool isBanned =
                    _draft.bannedMaps.any((m) => m.uuid == map.uuid);
                final bool isSelected =
                    _finalSelectedMap != null && _finalSelectedMap!.uuid == map.uuid;

                return ListTile(
                  onTap: () => _onMapTap(map),
                  leading: map.displayIcon.isNotEmpty
                      ? Image.network(map.displayIcon, width: 40, height: 40)
                      : const Icon(Icons.map),
                  title: Text(map.displayName),
                  subtitle: Text(
                    isSelected
                        ? 'Selected map'
                        : isBanned
                            ? 'Banned'
                            : 'Available',
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.star
                        : isBanned
                            ? Icons.block
                            : Icons.circle_outlined,
                    color: isSelected
                        ? Colors.amber
                        : isBanned
                            ? Colors.redAccent
                            : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                const Text(
                  'Agent Draft',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    'A picks: ${_draft.teamA.pickedAgents.length} / 5',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Chip(
                  label: Text(
                    'B picks: ${_draft.teamB.pickedAgents.length} / 5',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Chip(
                  label: Text(
                    'Total bans: ${_draft.bannedAgents.length}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTeamAgentsColumn(_draft.teamA)),
                const SizedBox(width: 8),
                Expanded(child: _buildTeamAgentsColumn(_draft.teamB)),
              ],
            ),
            const SizedBox(height: 8),
            _buildBannedAgentsRow(),
            const SizedBox(height: 8),
            GridView.builder(
              itemCount: _agents.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final agent = _agents[index];
                final isBanned =
                    _draft.bannedAgents.any((a) => a.uuid == agent.uuid);
                final inTeamA =
                    _draft.teamA.pickedAgents.any((a) => a.uuid == agent.uuid);
                final inTeamB =
                    _draft.teamB.pickedAgents.any((a) => a.uuid == agent.uuid);
                final isUsed = isBanned || inTeamA || inTeamB;

                return GestureDetector(
                  onTap: () => _onAgentTap(agent),
                  child: Stack(
                    children: [
                      Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: agent.iconUrl.isNotEmpty
                                  ? Image.network(agent.iconUrl,
                                      fit: BoxFit.contain)
                                  : const Icon(Icons.person),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agent.displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isUsed)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              isBanned
                                  ? Icons.block
                                  : inTeamA || inTeamB
                                      ? Icons.check
                                      : Icons.help_outline,
                              color: isBanned
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              size: 24,
                            ),
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

  Widget _buildTeamAgentsColumn(TeamDraft team) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (team.pickedAgents.isEmpty)
              const Text(
                'No picks yet.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else
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

  Widget _buildBannedAgentsRow() {
    if (_draft.bannedAgents.isEmpty) {
      return const Text(
        'Banned agents: none yet.',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banned Agents:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _draft.bannedAgents
              .map(
                (a) => Chip(
                  avatar: a.iconUrl.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(a.iconUrl))
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
