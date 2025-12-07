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
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      role: (json['role'] != null ? json['role']['displayName'] : 'Unknown') as String,
      iconUrl: (json['displayIcon'] ?? '') as String,
      isPlayable: (json['isPlayableCharacter'] ?? false) as bool,
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
      uuid: json['uuid'] as String,
      displayName: json['displayName'] as String,
      splash: (json['splash'] ?? '') as String,
      displayIcon: (json['displayIcon'] ?? '') as String,
    );
  }
}
