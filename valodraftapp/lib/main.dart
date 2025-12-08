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

  final List<ValorantMap> _teamAMapBanList = [];
  final List<ValorantMap> _teamBMapBanList = [];
  int _teamAMapBans = 0;
  int _teamBMapBans = 0;
  ValorantMap? _finalSelectedMap;

  final List<ValorantAgent> _teamAAgentBans = [];
  final List<ValorantAgent> _teamBAgentBans = [];

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
      default:
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
      return 'Draft Finished • Map: $mapName';
    }
    final t = _isTeamATurn ? 'Team A' : 'Team B';
    switch (_phase) {
      case DraftPhase.mapBanTeamA:
      case DraftPhase.mapBanTeamB:
        return '$t: Ban 3 maps';
      case DraftPhase.agentBan1TeamA:
      case DraftPhase.agentBan1TeamB:
        return '$t: Ban 3 agents';
      case DraftPhase.agentPick1TeamA:
      case DraftPhase.agentPick1TeamB:
        return '$t: Pick 3 agents';
      case DraftPhase.agentBan2TeamA:
      case DraftPhase.agentBan2TeamB:
        return '$t: Ban 2 agents';
      case DraftPhase.agentPick2TeamA:
      case DraftPhase.agentPick2TeamB:
        return '$t: Pick 2 agents';
      default:
        return '';
    }
  }

  void _onMapTap(ValorantMap map) {
    if (!_isMapPhase) {
      return;
    }

    final isTeamA = _phase == DraftPhase.mapBanTeamA;

    if (isTeamA && _teamAMapBans >= 3) return;
    if (!isTeamA && _teamBMapBans >= 3) return;

    final ok = _draft.banMap(map);
    if (!ok) return;

    if (isTeamA) {
      _teamAMapBanList.add(map);
      _teamAMapBans++;
      if (_teamAMapBans >= 3) _phase = DraftPhase.mapBanTeamB;
    } else {
      _teamBMapBanList.add(map);
      _teamBMapBans++;
    }

    if (_teamAMapBans >= 3 && _teamBMapBans >= 3) {
      _selectFinalMapFromRemaining();
      _phase = DraftPhase.agentBan1TeamA;
    }

    setState(() {});
  }

  void _onAgentTap(ValorantAgent agent) {
    if (_isMapPhase) return;

    switch (_phase) {
      case DraftPhase.agentBan1TeamA:
        _handleAgentBan(agent, true, 1);
        break;
      case DraftPhase.agentBan1TeamB:
        _handleAgentBan(agent, false, 1);
        break;
      case DraftPhase.agentPick1TeamA:
        _handleAgentPick(agent, true, 1);
        break;
      case DraftPhase.agentPick1TeamB:
        _handleAgentPick(agent, false, 1);
        break;
      case DraftPhase.agentBan2TeamA:
        _handleAgentBan(agent, true, 2);
        break;
      case DraftPhase.agentBan2TeamB:
        _handleAgentBan(agent, false, 2);
        break;
      case DraftPhase.agentPick2TeamA:
        _handleAgentPick(agent, true, 2);
        break;
      case DraftPhase.agentPick2TeamB:
        _handleAgentPick(agent, false, 2);
        break;
      default:
        break;
    }
  }

  void _handleAgentBan(ValorantAgent agent, bool isTeamA, int phase) {
    if (phase == 1) {
      if (isTeamA && _teamAFirstAgentBans >= 3) return;
      if (!isTeamA && _teamBFirstAgentBans >= 3) return;
    } else {
      if (isTeamA && _teamASecondAgentBans >= 2) return;
      if (!isTeamA && _teamBSecondAgentBans >= 2) return;
    }

    final ok = _draft.banAgent(agent);
    if (!ok) return;

    if (isTeamA) {
      if (!_teamAAgentBans.any((a) => a.uuid == agent.uuid)) {
        _teamAAgentBans.add(agent);
      }
    } else {
      if (!_teamBAgentBans.any((a) => a.uuid == agent.uuid)) {
        _teamBAgentBans.add(agent);
      }
    }

    if (phase == 1) {
      if (isTeamA) {
        _teamAFirstAgentBans++;
        if (_teamAFirstAgentBans >= 3) _phase = DraftPhase.agentBan1TeamB;
      } else {
        _teamBFirstAgentBans++;
        if (_teamBFirstAgentBans >= 3) _phase = DraftPhase.agentPick1TeamA;
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentBans++;
        if (_teamASecondAgentBans >= 2) _phase = DraftPhase.agentBan2TeamB;
      } else {
        _teamBSecondAgentBans++;
        if (_teamBSecondAgentBans >= 2) _phase = DraftPhase.agentPick2TeamA;
      }
    }

    setState(() {});
  }

  void _handleAgentPick(ValorantAgent agent, bool isTeamA, int phase) {
    final team = isTeamA ? _draft.teamA : _draft.teamB;

    if (phase == 1) {
      if (isTeamA && _teamAFirstAgentPicks >= 3) return;
      if (!isTeamA && _teamBFirstAgentPicks >= 3) return;
    } else {
      if (isTeamA && _teamASecondAgentPicks >= 2) return;
      if (!isTeamA && _teamBSecondAgentPicks >= 2) return;
    }

    final ok = _draft.pickAgent(agent, team);
    if (!ok) return;

    if (phase == 1) {
      if (isTeamA) {
        _teamAFirstAgentPicks++;
        if (_teamAFirstAgentPicks >= 3) _phase = DraftPhase.agentPick1TeamB;
      } else {
        _teamBFirstAgentPicks++;
        if (_teamBFirstAgentPicks >= 3) _phase = DraftPhase.agentBan2TeamA;
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentPicks++;
        if (_teamASecondAgentPicks >= 2) _phase = DraftPhase.agentPick2TeamB;
      } else {
        _teamBSecondAgentPicks++;
        if (_teamBSecondAgentPicks >= 2) _phase = DraftPhase.done;
      }
    }

    setState(() {});
  }

  void _selectFinalMapFromRemaining() {
    final bannedIds = _draft.bannedMaps.map((m) => m.uuid).toSet();
    final remaining = _maps.where((m) => !bannedIds.contains(m.uuid)).toList();
    if (remaining.isNotEmpty) {
      remaining.shuffle();
      _finalSelectedMap = remaining.first;
    }
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
      if (_phase == DraftPhase.agentBan1TeamA ||
          _phase == DraftPhase.agentBan1TeamB ||
          _phase == DraftPhase.agentBan2TeamA ||
          _phase == DraftPhase.agentBan2TeamB) {
        start = Colors.redAccent.shade200;
        end = Colors.red.shade800;
        icon = Icons.block;
      } else {
        start = Colors.blueAccent.shade200;
        end = Colors.blue.shade800;
        icon = Icons.person;
      }
    }

    final teamLabel =
        _phase == DraftPhase.done ? 'Draft Finished' : (_isTeamATurn ? 'Team A' : 'Team B');

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
                Text(_phaseTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_phaseSubtitle, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(teamLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBanStrip(List<ValorantMap> maps, Color tint) {
    if (maps.isEmpty) {
      return const Text('No bans yet',
          style: TextStyle(fontSize: 11, color: Colors.grey));
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
                  ? Image.network(img, width: 36, height: 36, fit: BoxFit.cover)
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

  Widget _buildMapSection() {
    final mapTitle =
        _finalSelectedMap != null ? _finalSelectedMap!.displayName : 'Not selected';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map),
                const SizedBox(width: 8),
                const Text('Map Draft',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Chip(label: Text('A bans: $_teamAMapBans / 3')),
                const SizedBox(width: 4),
                Chip(label: Text('B bans: $_teamBMapBans / 3')),
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
                      const Text('Team A Bans',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildMapBanStrip(_teamAMapBanList, Colors.blueAccent),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Chosen Map',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (_finalSelectedMap == null)
                        const Text('Not selected',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey))
                      else
                        Column(
                          children: [
                            if (_finalSelectedMap!.splash.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _finalSelectedMap!.splash,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(mapTitle,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Team B Bans',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildMapBanStrip(_teamBMapBanList, Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Maps to choose from',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _maps.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, childAspectRatio: .9),
              itemBuilder: (context, i) {
                final m = _maps[i];
                final bannedA =
                    _teamAMapBanList.any((x) => x.uuid == m.uuid);
                final bannedB =
                    _teamBMapBanList.any((x) => x.uuid == m.uuid);
                final selected =
                    _finalSelectedMap != null && _finalSelectedMap!.uuid == m.uuid;
                return GestureDetector(
                  onTap: () => _onMapTap(m),
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
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.map),
                            ),
                            const SizedBox(height: 4),
                            Text(m.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11)),
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

  Widget _buildBannedAgentsRow() {
    final hasBans =
        _teamAAgentBans.isNotEmpty || _teamBAgentBans.isNotEmpty;

    if (!hasBans) {
      return const Text('Banned agents: none yet.',
          style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banned Agents by Team',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team A',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _teamAAgentBans
                        .map((a) => Chip(
                              shape: StadiumBorder(
                                side: BorderSide(
                                    color: Colors.blueAccent.withOpacity(.7)),
                              ),
                              avatar: a.iconUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(a.iconUrl))
                                  : const CircleAvatar(
                                      child:
                                          Icon(Icons.person, size: 14)),
                              label: Text(a.displayName,
                                  style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team B',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _teamBAgentBans
                        .map((a) => Chip(
                              shape: StadiumBorder(
                                side: BorderSide(
                                    color: Colors.redAccent.withOpacity(.7)),
                              ),
                              avatar: a.iconUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(a.iconUrl))
                                  : const CircleAvatar(
                                      child:
                                          Icon(Icons.person, size: 14)),
                              label: Text(a.displayName,
                                  style: const TextStyle(fontSize: 11)),
                            ))
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

  Widget _buildAgentSection() {
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
                Text('Agent Draft',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                    label: Text(
                        'A picks: ${_draft.teamA.pickedAgents.length} / 5')),
                Chip(
                    label: Text(
                        'B picks: ${_draft.teamB.pickedAgents.length} / 5')),
                Chip(label: Text('Total bans: ${_draft.bannedAgents.length}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTeamAgentsColumn(_draft.teamA)),
                const SizedBox(width: 8),
                Expanded(child: _buildTeamAgentsColumn(_draft.teamB)),
              ],
            ),
            const SizedBox(height: 12),
            _buildBannedAgentsRow(),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _agents.length,
              padding: const EdgeInsets.all(4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, childAspectRatio: .75),
              itemBuilder: (context, i) {
                final a = _agents[i];

                final bannedA =
                    _teamAAgentBans.any((x) => x.uuid == a.uuid);
                final bannedB =
                    _teamBAgentBans.any((x) => x.uuid == a.uuid);
                final inA = _draft.teamA.pickedAgents
                    .any((x) => x.uuid == a.uuid);
                final inB = _draft.teamB.pickedAgents
                    .any((x) => x.uuid == a.uuid);

                final used = bannedA || bannedB || inA || inB;

                return GestureDetector(
                  onTap: () => _onAgentTap(a),
                  child: Stack(
                    children: [
                      Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: a.iconUrl.isNotEmpty
                                  ? Image.network(a.iconUrl,
                                      fit: BoxFit.contain)
                                  : const Icon(Icons.person),
                            ),
                            const SizedBox(height: 4),
                            Text(a.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11)),
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
                              bannedA || bannedB
                                  ? Icons.block
                                  : Icons.check,
                              color: bannedA || bannedB
                                  ? Colors.white
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
      color: Colors.white.withOpacity(.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            if (team.pickedAgents.isEmpty)
              const Text('No picks yet.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            if (team.pickedAgents.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: team.pickedAgents
                    .map((a) => Chip(
                          avatar: a.iconUrl.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(a.iconUrl))
                              : const CircleAvatar(
                                  child: Icon(Icons.person, size: 14)),
                          label: Text(a.displayName,
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
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
            onPressed: () {
              setState(() {
                _draft.reset();
                _phase = DraftPhase.mapBanTeamA;
                _teamAMapBans = 0;
                _teamBMapBans = 0;
                _teamAMapBanList.clear();
                _teamBMapBanList.clear();
                _teamAAgentBans.clear();
                _teamBAgentBans.clear();
                _teamAFirstAgentBans = 0;
                _teamBFirstAgentBans = 0;
                _teamAFirstAgentPicks = 0;
                _teamBFirstAgentPicks = 0;
                _teamASecondAgentBans = 0;
                _teamBSecondAgentBans = 0;
                _teamASecondAgentPicks = 0;
                _teamBSecondAgentPicks = 0;
                _finalSelectedMap = null;
                _loadFuture = _loadData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              ],
            ),
          );
        },
      ),
    );
  }
}