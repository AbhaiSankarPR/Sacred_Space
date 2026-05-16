import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../settings/family_request_model.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dummy data for now as requested
    final List<FamilyConnection> dummyConnections = [
      FamilyConnection(
        relation: "CHILD",
        relatedUser: RelatedUser(
          id: "1884b946-ac8a-44d9-ac2e-d46289de51da",
          role: "MEMBER",
          profile: FamilyProfile(name: "Akhil"),
        ),
      ),
      FamilyConnection(
        relation: "SPOUSE",
        relatedUser: RelatedUser(
          id: "7b5bb0bf-5cdc-460b-aa3b-d8dbbfe751c3",
          role: "MEMBER",
          profile: FamilyProfile(name: "Anjali"),
        ),
      ),
    ];

    final connections =
        (user?.familyConnections.isNotEmpty ?? false)
            ? user!.familyConnections
            : dummyConnections;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(loc.familyMembers),
        centerTitle: true,
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final conn = connections[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF5D3A99)),
              ),
              title: Text(
                conn.relatedUser.profile.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(conn.relation),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  conn.relatedUser.role?.toUpperCase() ?? "MEMBER",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
