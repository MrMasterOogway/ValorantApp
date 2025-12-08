class ValorantAgent {
  final String uuid;
  final String displayName;
  final String role;
  final String iconUrl;
  final bool isPlayable;

  ValorantAgent({
    required this.uuid,
    required this.displayName,
    required this.role,
    required this.iconUrl,
    required this.isPlayable,
  });

  factory ValorantAgent.fromJson(Map<String, dynamic> json) {
    return ValorantAgent(
      uuid: json['uuid'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role']?['displayName'] ?? 'Unknown',
      iconUrl: json['displayIcon'] ?? '',
      isPlayable: json['isPlayableCharacter'] ?? false,
    );
  }
}

class ValorantMap {
  final String uuid;
  final String displayName;
  final String splash;
  final String displayIcon;

  ValorantMap({
    required this.uuid,
    required this.displayName,
    required this.splash,
    required this.displayIcon,
  });

  factory ValorantMap.fromJson(Map<String, dynamic> json) {
    return ValorantMap(
      uuid: json['uuid'] ?? '',
      displayName: json['displayName'] ?? '',
      splash: json['splash'] ?? '',
      displayIcon: json['displayIcon'] ?? '',
    );
  }
}

class TeamDraft {
  final String name;
  final List<ValorantAgent> pickedAgents;

  TeamDraft({
    required this.name,
    List<ValorantAgent>? pickedAgents,
  }) : pickedAgents = pickedAgents ?? [];
}
