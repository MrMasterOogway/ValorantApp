import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ValorantApi {
  static const String _baseUrl = 'https://valorant-api.com/v1';

  Future<List<ValorantAgent>> fetchAgents() async {
    final uri = Uri.parse('$_baseUrl/agents?isPlayableCharacter=true');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load agents');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = data['data'] ?? [];
    return results.map((e) => ValorantAgent.fromJson(e)).toList();
  }

  Future<List<ValorantMap>> fetchMaps() async {
    final uri = Uri.parse('$_baseUrl/maps');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load maps');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = data['data'] ?? [];
    return results.map((e) => ValorantMap.fromJson(e)).toList();
  }
}
