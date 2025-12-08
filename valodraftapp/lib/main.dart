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
      theme: ThemeData.dark(useMaterial3: true),
      home: const DraftScreen(),
    );
  }
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

  void _showAgentActionSheet(ValorantAgent agent) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Ban Agent (Global)'),
                onTap: () {
                  final ok = _draft.banAgent(agent);
                  Navigator.pop(context);
                  _showResult(ok, 'agent ban');
                  setState(() {});
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.looks_one),
                title: const Text('Pick for Team A'),
                onTap: () {
                  final ok = _draft.pickAgent(agent, _draft.teamA);
                  Navigator.pop(context);
                  _showResult(ok, 'Team A agent pick');
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.looks_two),
                title: const Text('Pick for Team B'),
                onTap: () {
                  final ok = _draft.pickAgent(agent, _draft.teamB);
                  Navigator.pop(context);
                  _showResult(ok, 'Team B agent pick');
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMapActionSheet(ValorantMap map) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Ban Map (Global)'),
                onTap: () {
                  final ok = _draft.banMap(map);
                  Navigator.pop(context);
                  _showResult(ok, 'map ban');
                  setState(() {});
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.looks_one),
                title: const Text('Pick for Team A'),
                onTap: () {
                  final ok = _draft.pickMap(map, _draft.teamA);
                  Navigator.pop(context);
                  _showResult(ok, 'Team A map pick');
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.looks_two),
                title: const Text('Pick for Team B'),
                onTap: () {
                  final ok = _draft.pickMap(map, _draft.teamB);
                  Navigator.pop(context);
                  _showResult(ok, 'Team B map pick');
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResult(bool success, String action) {
    final text = success
        ? 'Successful $action'
        : 'Cannot perform $action (limit reached or already used)';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VALORANT Draft / Ban'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agents'),
              Tab(text: 'Maps'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _draft.reset();
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
            return TabBarView(
              children: [
                _buildAgentsTab(),
                _buildMapsTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAgentsTab() {
    return Column(
      children: [
        _buildTeamSummaryAgents(),
        const Divider(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _agents.length,
            itemBuilder: (context, index) {
              final agent = _agents[index];
              final isUsed = _draft.bannedAgents.any((a) => a.uuid == agent.uuid) ||
                  _draft.teamA.pickedAgents.any((a) => a.uuid == agent.uuid) ||
                  _draft.teamB.pickedAgents.any((a) => a.uuid == agent.uuid);

              return GestureDetector(
                onTap: () => _showAgentActionSheet(agent),
                child: Opacity(
                  opacity: isUsed ? 0.3 : 1.0,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: agent.iconUrl.isNotEmpty
                              ? Image.network(agent.iconUrl, fit: BoxFit.contain)
                              : const Icon(Icons.person),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agent.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          agent.role,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapsTab() {
    return Column(
      children: [
        _buildTeamSummaryMaps(),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _maps.length,
            itemBuilder: (context, index) {
              final map = _maps[index];
              final isUsed = _draft.bannedMaps.any((m) => m.uuid == map.uuid) ||
                  _draft.teamA.pickedMaps.any((m) => m.uuid == map.uuid) ||
                  _draft.teamB.pickedMaps.any((m) => m.uuid == map.uuid);

              return ListTile(
                onTap: () => _showMapActionSheet(map),
                leading: map.displayIcon.isNotEmpty
                    ? Image.network(map.displayIcon)
                    : const Icon(Icons.map),
                title: Text(map.displayName),
                subtitle: Text(
                  isUsed ? 'Already used' : 'Tap to ban/pick for a team',
                ),
                trailing: Icon(
                  _draft.bannedMaps.any((m) => m.uuid == map.uuid)
                      ? Icons.block
                      : _draft.teamA.pickedMaps.any((m) => m.uuid == map.uuid) ||
                              _draft.teamB.pickedMaps.any((m) => m.uuid == map.uuid)
                          ? Icons.check
                          : Icons.circle_outlined,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSummaryAgents() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('Agent bans: '
                    '${_draft.bannedAgents.length} / ${DraftState.maxAgentBans}'),
              ),
              Chip(
                label: Text('Team A picks: '
                    '${_draft.teamA.pickedAgents.length} / ${DraftState.maxAgentPicksPerTeam}'),
              ),
              Chip(
                label: Text('Team B picks: '
                    '${_draft.teamB.pickedAgents.length} / ${DraftState.maxAgentPicksPerTeam}'),
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
        ],
      ),
    );
  }

  Widget _buildTeamSummaryMaps() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text('Map bans: '
                    '${_draft.bannedMaps.length} / ${DraftState.maxMapBans}'),
              ),
              Chip(
                label: Text('Team A maps: '
                    '${_draft.teamA.pickedMaps.length} / ${DraftState.maxMapPicksPerTeam}'),
              ),
              Chip(
                label: Text('Team B maps: '
                    '${_draft.teamB.pickedMaps.length} / ${DraftState.maxMapPicksPerTeam}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTeamMapsColumn(_draft.teamA)),
              const SizedBox(width: 8),
              Expanded(child: _buildTeamMapsColumn(_draft.teamB)),
            ],
          ),
          const SizedBox(height: 8),
          _buildBannedMapsRow(),
        ],
      ),
    );
  }

  Widget _buildTeamAgentsColumn(TeamDraft team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: team.pickedAgents
                  .map((a) => Chip(
                        avatar: a.iconUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(a.iconUrl),
                              )
                            : const CircleAvatar(child: Icon(Icons.person, size: 14)),
                        label: Text(
                          a.displayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMapsColumn(TeamDraft team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: team.pickedMaps
                  .map((m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            if (m.displayIcon.isNotEmpty)
                              Image.network(m.displayIcon, width: 24, height: 24)
                            else
                              const Icon(Icons.map, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                m.displayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannedAgentsRow() {
    if (_draft.bannedAgents.isEmpty) {
      return const Text('No agent bans yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banned Agents:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _draft.bannedAgents
              .map(
                (a) => Chip(
                  avatar: a.iconUrl.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(a.iconUrl))
                      : const CircleAvatar(child: Icon(Icons.person, size: 14)),
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

  Widget _buildBannedMapsRow() {
    if (_draft.bannedMaps.isEmpty) {
      return const Text('No map bans yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banned Maps:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _draft.bannedMaps
              .map(
                (m) => Chip(
                  avatar: m.displayIcon.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(m.displayIcon))
                      : const CircleAvatar(child: Icon(Icons.map, size: 14)),
                  label: Text(
                    m.displayName,
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
