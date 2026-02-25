import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../auth/auth_service.dart';
import '../../widgets/app_drawer.dart';

class Member {
  final String id, name, email, phone, houseName;

  Member({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.phone, 
    required this.houseName
  });
}

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  String _searchQuery = "";
  
  // DUMMY DATA: This matches the structure of your backend Member profile
  final List<Member> _allMembers = [
    Member(id: "101", name: "Naveen K.", email: "naveen@church.com", phone: "9876543210", houseName: "Grace Villa"),
    Member(id: "102", name: "Anish Jacob", email: "anish@church.com", phone: "9845012345", houseName: "Bethel House"),
    Member(id: "103", name: "Sarah Joseph", email: "sarah@church.com", phone: "9995544332", houseName: "Olive Gardens"),
    Member(id: "104", name: "Abhai Sankar", email: "abhai@church.com", phone: "9446001122", houseName: "Sion Bhavan"),
    Member(id: "105", name: "Mariamma John", email: "maria@church.com", phone: "9123456789", houseName: "Ebenezer"),
  ];

  // Function to handle member deletion from local list
  Future<void> _removeMember(Member member) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove ${member.name}?"),
        content: const Text("This user will be permanently removed from the church directory."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Logic for dummy data: remove from the local list
      setState(() {
        _allMembers.removeWhere((m) => m.id == member.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${member.name} removed")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    // Security Gate: Ensure only Priest can view this screen
    if (user?.role.toLowerCase() != 'priest') {
      return Scaffold(body: Center(child: Text(loc.accessType("DENIED"))));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Filter Logic for Search Bar
    final filteredMembers = _allMembers.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) || 
             m.houseName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user!),
      appBar: AppBar(
        title: Text(loc.memberDirectory, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF5D3A99),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search name or house name...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                  borderSide: BorderSide.none
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // --- MEMBER LIST ---
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(child: Text("No members found matching search."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return _MemberTile(
                        member: member, 
                        theme: theme, 
                        isDark: isDark,
                        onDelete: () => _removeMember(member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onDelete;

  const _MemberTile({
    required this.member, 
    required this.theme, 
    required this.isDark, 
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF5D3A99)),
        ),
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.houseName, style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(member.phone, style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CALL BUTTON
            IconButton(
              icon: const Icon(Icons.phone_in_talk_outlined, color: Colors.green),
              onPressed: () {
                // Future: URL Launcher logic
              },
            ),
            // DELETE BUTTON (Priest only)
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}