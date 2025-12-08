import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'draft_state.dart';
import 'models/models.dart';
import 'api/valorant_api.dart';
import 'widgets/phase_banner.dart';
import 'widgets/map_section.dart';
import 'widgets/agent_section.dart';
import 'widgets/final_summary_section.dart';

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

  Timer? _timer;
  int _secondsLeft = 30;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
    _resetTimer();
  }

  Future<void> _loadData() async {
    final agents = await _api.fetchAgents();
    final maps = await _api.fetchMaps();

    final filteredMaps = maps.where((m) {
      final name = m.displayName.toLowerCase();
      if (name.contains('scrim') ||
          name.contains('skirmish') ||
          name.contains('basic training') ||
          name.contains('the range') ||
          name.contains('range') ||
          name.contains('kasbah') ||
          name.contains('district') ||
          name.contains('drift') ||
          name.contains('piazza')) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _agents = agents;
      _maps = filteredMaps;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _secondsLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _autoActForCurrentPhase();
      }
    });
  }

  void _setPhase(DraftPhase newPhase) {
    if (_phase != newPhase) {
      _phase = newPhase;
      if (_phase != DraftPhase.done) {
        _resetTimer();
      } else {
        _timer?.cancel();
        _secondsLeft = 0;
      }
    }
  }

  void _autoActForCurrentPhase() {
    if (!mounted) return;

    final currentPhase = _phase;

    switch (_phase) {
      case DraftPhase.mapBanTeamA:
      case DraftPhase.mapBanTeamB:
        _autoBanMap();
        break;
      case DraftPhase.agentBan1TeamA:
        _autoBanAgent(true, 1);
        break;
      case DraftPhase.agentBan1TeamB:
        _autoBanAgent(false, 1);
        break;
      case DraftPhase.agentPick1TeamA:
        _autoPickAgent(true, 1);
        break;
      case DraftPhase.agentPick1TeamB:
        _autoPickAgent(false, 1);
        break;
      case DraftPhase.agentBan2TeamA:
        _autoBanAgent(true, 2);
        break;
      case DraftPhase.agentBan2TeamB:
        _autoBanAgent(false, 2);
        break;
      case DraftPhase.agentPick2TeamA:
        _autoPickAgent(true, 2);
        break;
      case DraftPhase.agentPick2TeamB:
        _autoPickAgent(false, 2);
        break;
      case DraftPhase.done:
        break;
    }

    if (!mounted) return;

    if (_phase == currentPhase && _phase != DraftPhase.done) {
      _resetTimer();
    }
}

  List<ValorantMap> _availableMapsForBan() {
    final banned = _draft.bannedMaps.map((m) => m.uuid).toSet();
    return _maps.where((m) => !banned.contains(m.uuid)).toList();
  }

  List<ValorantAgent> _availableAgentsForAction() {
    final used = <String>{};
    used.addAll(_draft.bannedAgents.map((a) => a.uuid));
    used.addAll(_draft.teamA.pickedAgents.map((a) => a.uuid));
    used.addAll(_draft.teamB.pickedAgents.map((a) => a.uuid));
    return _agents.where((a) => !used.contains(a.uuid)).toList();
  }

  void _autoBanMap() {
    if (!_isMapPhase) return;
    final candidates = _availableMapsForBan();
    if (candidates.isEmpty) return;
    final randomMap = candidates[_random.nextInt(candidates.length)];
    _onMapTap(randomMap);
  }

  void _autoBanAgent(bool isTeamA, int phase) {
    final candidates = _availableAgentsForAction();
    if (candidates.isEmpty) return;
    final agent = candidates[_random.nextInt(candidates.length)];
    _handleAgentBan(agent, isTeamA, phase);
  }

  void _autoPickAgent(bool isTeamA, int phase) {
    final candidates = _availableAgentsForAction();
    if (candidates.isEmpty) return;
    final agent = candidates[_random.nextInt(candidates.length)];
    _handleAgentPick(agent, isTeamA, phase);
  }

  bool get _isMapPhase =>
      _phase == DraftPhase.mapBanTeamA || _phase == DraftPhase.mapBanTeamB;

  bool get _isAgentPhase =>
      _phase == DraftPhase.agentBan1TeamA ||
      _phase == DraftPhase.agentBan1TeamB ||
      _phase == DraftPhase.agentPick1TeamA ||
      _phase == DraftPhase.agentPick1TeamB ||
      _phase == DraftPhase.agentBan2TeamA ||
      _phase == DraftPhase.agentBan2TeamB ||
      _phase == DraftPhase.agentPick2TeamA ||
      _phase == DraftPhase.agentPick2TeamB;

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

  bool get _isBanPhase {
    return _phase == DraftPhase.agentBan1TeamA ||
        _phase == DraftPhase.agentBan1TeamB ||
        _phase == DraftPhase.agentBan2TeamA ||
        _phase == DraftPhase.agentBan2TeamB;
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

  final currentPhase = _phase;

  final isTeamA = _phase == DraftPhase.mapBanTeamA;

  if (isTeamA && _teamAMapBans >= 3) return;
  if (!isTeamA && _teamBMapBans >= 3) return;

  final ok = _draft.banMap(map);
  if (!ok) return;

  if (isTeamA) {
    _teamAMapBanList.add(map);
    _teamAMapBans++;
    if (_teamAMapBans >= 3) _setPhase(DraftPhase.mapBanTeamB);
  } else {
    _teamBMapBanList.add(map);
    _teamBMapBans++;
  }

  if (_teamAMapBans >= 3 && _teamBMapBans >= 3) {
    _selectFinalMapFromRemaining();
    _setPhase(DraftPhase.agentBan1TeamA);
  }

  setState(() {});

  if (_phase == currentPhase && _phase != DraftPhase.done) {
    _resetTimer();
  }
}

  void _onAgentTap(ValorantAgent agent) {
    if (!_isAgentPhase) return;

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
        if (_teamAFirstAgentBans >= 3) _setPhase(DraftPhase.agentBan1TeamB);
      } else {
        _teamBFirstAgentBans++;
        if (_teamBFirstAgentBans >= 3) _setPhase(DraftPhase.agentPick1TeamA);
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentBans++;
        if (_teamASecondAgentBans >= 2) _setPhase(DraftPhase.agentBan2TeamB);
      } else {
        _teamBSecondAgentBans++;
        if (_teamBSecondAgentBans >= 2) _setPhase(DraftPhase.agentPick2TeamA);
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
        if (_teamAFirstAgentPicks >= 3) _setPhase(DraftPhase.agentPick1TeamB);
      } else {
        _teamBFirstAgentPicks++;
        if (_teamBFirstAgentPicks >= 3) _setPhase(DraftPhase.agentBan2TeamA);
      }
    } else {
      if (isTeamA) {
        _teamASecondAgentPicks++;
        if (_teamASecondAgentPicks >= 2) _setPhase(DraftPhase.agentPick2TeamB);
      } else {
        _teamBSecondAgentPicks++;
        if (_teamBSecondAgentPicks >= 2) _setPhase(DraftPhase.done);
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              _resetTimer();
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

          if (_phase == DraftPhase.done) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  PhaseBanner(
                    title: _phaseTitle,
                    subtitle: _phaseSubtitle,
                    isMapPhase: false,
                    isBanPhase: false,
                    isDone: true,
                    isTeamATurn: false,
                    secondsLeft: _secondsLeft,
                  ),
                  const SizedBox(height: 12),
                  FinalSummarySection(
                    finalMap: _finalSelectedMap,
                    teamA: _draft.teamA,
                    teamB: _draft.teamB,
                    teamAMapBans: _teamAMapBanList,
                    teamBMapBans: _teamBMapBanList,
                    teamAAgentBans: _teamAAgentBans,
                    teamBAgentBans: _teamBAgentBans,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                PhaseBanner(
                  title: _phaseTitle,
                  subtitle: _phaseSubtitle,
                  isMapPhase: _isMapPhase,
                  isBanPhase: _isBanPhase,
                  isDone: false,
                  isTeamATurn: _isTeamATurn,
                  secondsLeft: _secondsLeft,
                ),
                const SizedBox(height: 12),
                if (_isMapPhase)
                  MapSection(
                    maps: _maps,
                    teamAMapBans: _teamAMapBanList,
                    teamBMapBans: _teamBMapBanList,
                    finalSelectedMap: _finalSelectedMap,
                    onMapTap: _onMapTap,
                  ),
                if (_isAgentPhase)
                  AgentSection(
                    draft: _draft,
                    agents: _agents,
                    teamAAgentBans: _teamAAgentBans,
                    teamBAgentBans: _teamBAgentBans,
                    onAgentTap: _onAgentTap,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
