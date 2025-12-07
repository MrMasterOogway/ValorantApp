import 'models.dart';

class TeamDraft {
  final String name;
  final List<ValorantAgent> pickedAgents = [];
  final List<ValorantMap> pickedMaps = [];

  TeamDraft(this.name);
}

class DraftState {
  final TeamDraft teamA = TeamDraft('Team A');
  final TeamDraft teamB = TeamDraft('Team B');

  final List<ValorantAgent> bannedAgents = [];
  final List<ValorantMap> bannedMaps = [];

  static const int maxAgentBans = 5;
  static const int maxAgentPicksPerTeam = 5;
  static const int maxMapBans = 3;
  static const int maxMapPicksPerTeam = 3;

  bool banAgent(ValorantAgent agent) {
    if (bannedAgents.length >= maxAgentBans) return false;
    if (_isAgentGloballyUsed(agent)) return false;
    bannedAgents.add(agent);
    return true;
  }

  bool pickAgent(ValorantAgent agent, TeamDraft team) {
    if (_isAgentGloballyUsed(agent)) return false;

    if (team == teamA) {
      if (teamA.pickedAgents.length >= maxAgentPicksPerTeam) return false;
      teamA.pickedAgents.add(agent);
      return true;
    } else {
      if (teamB.pickedAgents.length >= maxAgentPicksPerTeam) return false;
      teamB.pickedAgents.add(agent);
      return true;
    }
  }

  bool banMap(ValorantMap map) {
    if (bannedMaps.length >= maxMapBans) return false;
    if (_isMapGloballyUsed(map)) return false;
    bannedMaps.add(map);
    return true;
  }

  bool pickMap(ValorantMap map, TeamDraft team) {
    if (_isMapGloballyUsed(map)) return false;

    if (team == teamA) {
      if (teamA.pickedMaps.length >= maxMapPicksPerTeam) return false;
      teamA.pickedMaps.add(map);
      return true;
    } else {
      if (teamB.pickedMaps.length >= maxMapPicksPerTeam) return false;
      teamB.pickedMaps.add(map);
      return true;
    }
  }

  bool _isAgentGloballyUsed(ValorantAgent agent) {
    return bannedAgents.any((a) => a.uuid == agent.uuid) ||
        teamA.pickedAgents.any((a) => a.uuid == agent.uuid) ||
        teamB.pickedAgents.any((a) => a.uuid == agent.uuid);
  }

  bool _isMapGloballyUsed(ValorantMap map) {
    return bannedMaps.any((m) => m.uuid == map.uuid) ||
        teamA.pickedMaps.any((m) => m.uuid == map.uuid) ||
        teamB.pickedMaps.any((m) => m.uuid == map.uuid);
  }

  void reset() {
    bannedAgents.clear();
    bannedMaps.clear();
    teamA.pickedAgents.clear();
    teamA.pickedMaps.clear();
    teamB.pickedAgents.clear();
    teamB.pickedMaps.clear();
  }
}
