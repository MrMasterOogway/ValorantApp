import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ValorantApi {
  static const _baseUrl = 'https://valorant-api.com';

  Future<List<ValorantAgent>> fetchAgents() async {
    final uri = Uri.parse('$_baseUrl/v1/agents');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load agents: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'];

    return data
        .map((e) => ValorantAgent.fromJson(e as Map<String, dynamic>))
        .where((a) => a.isPlayable)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<List<ValorantMap>> fetchMaps() async {
    final uri = Uri.parse('$_baseUrl/v1/maps');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to load maps: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'];

    return data
        .map((e) => ValorantMap.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }
}
