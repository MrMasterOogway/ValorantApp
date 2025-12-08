import 'models/models.dart';

class DraftState {
  static const int maxAgentBans = 10;
  static const int maxAgentPicksPerTeam = 5;
  static const int maxMapBans = 6;

  final TeamDraft teamA = TeamDraft(name: 'Team A');
  final TeamDraft teamB = TeamDraft(name: 'Team B');

  final List<ValorantAgent> bannedAgents = [];
  final List<ValorantMap> bannedMaps = [];

  bool _isAgentGloballyUsed(ValorantAgent agent) {
    final id = agent.uuid;
    if (bannedAgents.any((a) => a.uuid == id)) return true;
    if (teamA.pickedAgents.any((a) => a.uuid == id)) return true;
    if (teamB.pickedAgents.any((a) => a.uuid == id)) return true;
    return false;
  }

  bool banAgent(ValorantAgent agent) {
    if (bannedAgents.length >= maxAgentBans) return false;
    if (_isAgentGloballyUsed(agent)) return false;
    bannedAgents.add(agent);
    return true;
  }

  bool pickAgent(ValorantAgent agent, TeamDraft team) {
    if (_isAgentGloballyUsed(agent)) return false;
    if (team.pickedAgents.length >= maxAgentPicksPerTeam) return false;
    team.pickedAgents.add(agent);
    return true;
  }

  bool banMap(ValorantMap map) {
    if (bannedMaps.length >= maxMapBans) return false;
    if (bannedMaps.any((m) => m.uuid == map.uuid)) return false;
    bannedMaps.add(map);
    return true;
  }

  void reset() {
    teamA.pickedAgents.clear();
    teamB.pickedAgents.clear();
    bannedAgents.clear();
    bannedMaps.clear();
  }
}
