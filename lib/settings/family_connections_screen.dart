import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../auth/auth_service.dart';
import './family_request_model.dart';

class FamilyConnectionsScreen extends StatefulWidget {
  const FamilyConnectionsScreen({super.key});

  @override
  State<FamilyConnectionsScreen> createState() =>
      _FamilyConnectionsScreenState();
}

class _FamilyConnectionsScreenState extends State<FamilyConnectionsScreen> {
  final AuthService _authService = AuthService();
  late Future<List<FamilyRequest>> _receivedRequests;
  late Future<List<FamilyRequest>> _sentRequests;

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  void _refreshRequests() {
    setState(() {
      _receivedRequests = _authService.getReceivedFamilyRequests();
      _sentRequests = _authService.getSentFamilyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loc.familyConnections,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF5D3A99),
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            tabs: [
              Tab(text: loc.receivedRequests.toUpperCase()),
              Tab(text: loc.sentRequests.toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildReceivedTab(loc), _buildSentTab(loc)],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showSendRequestDialog(loc),
          backgroundColor: const Color(0xFF5D3A99),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            loc.addFamily,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedTab(AppLocalizations loc) {
    return FutureBuilder<List<FamilyRequest>>(
      future: _receivedRequests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(loc.errorOccurred));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(child: Text(loc.noRequests));
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(req, loc, isReceived: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildSentTab(AppLocalizations loc) {
    return FutureBuilder<List<FamilyRequest>>(
      future: _sentRequests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(loc.errorOccurred));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(child: Text(loc.noRequests));
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _buildRequestCard(req, loc, isReceived: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(
    FamilyRequest req,
    AppLocalizations loc, {
    required bool isReceived,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                  child: const Icon(Icons.person, color: Color(0xFF5D3A99)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.relatedUser.profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${loc.relation}: ${req.relation}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (isReceived) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed:
                        () => _handleAction(req.relatedUser.id, 'accept', loc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed:
                        () => _handleAction(req.relatedUser.id, 'reject', loc),
                  ),
                ] else
                  TextButton(
                    onPressed:
                        () => _handleAction(req.relatedUser.id, 'cancel', loc),
                    child: Text(
                      loc.cancel,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    String id,
    String action,
    AppLocalizations loc,
  ) async {
    try {
      await _authService.handleFamilyRequest(id, action);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.requestSent)));
      _refreshRequests();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.requestFailed)));
    }
  }

  void _showSendRequestDialog(AppLocalizations loc) {
    final userIdController = TextEditingController();
    String selectedRelation = "PARENT";
    final relations = ["PARENT", "CHILD", "SPOUSE", "SIBLING"];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(loc.addFamily),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: userIdController,
                        decoration: InputDecoration(
                          labelText: loc.userId,
                          hintText: "Enter unique ID",
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRelation,
                        items:
                            relations
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => selectedRelation = v!),
                        decoration: InputDecoration(labelText: loc.relation),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (userIdController.text.isNotEmpty) {
                          try {
                            await _authService.sendFamilyRequest(
                              inviteCode: userIdController.text,
                              relation: selectedRelation,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.requestSent)),
                            );
                            _refreshRequests();
                          } catch (e) {
                            final errorMsg = e.toString().replaceAll('Exception: ', '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          }
                        }
                      },
                      child: Text(loc.send),
                    ),
                  ],
                ),
          ),
    );
  }
}
