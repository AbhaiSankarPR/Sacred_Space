import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../auth/auth_service.dart';
import '../../widgets/app_drawer.dart';

class Member {
  final String name;
  final String email;
  final String phone;
  final String houseName;

  Member({required this.name, required this.email, required this.phone, required this.houseName});
}

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  String _searchQuery = "";
  
  // Mock Data - In a real app, fetch this from a MemberService
  final List<Member> _allMembers = [
    Member(name: "Naveen K.", email: "naveen@email.com", phone: "+91 9876543210", houseName: "Grace Villa"),
    Member(name: "Anish Jacob", email: "anish@email.com", phone: "+91 9845012345", houseName: "Bethel House"),
    Member(name: "Sarah Joseph", email: "sarah@email.com", phone: "+91 9995544332", houseName: "Olive Gardens"),
    // Add more mock members here...
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    // Security check
    if (user?.role.toLowerCase() != 'priest') {
      return Scaffold(body: Center(child: Text(loc.accessType("DENIED"))));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter logic
    final filteredMembers = _allMembers.where((m) {
      return m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             m.houseName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Using AppDrawer instead of leading back button
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
                hintText: "${loc.enterChurch}...", // Reusing search-like loc key
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // --- MEMBER LIST ---
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(child: Text(loc.noBookingsFound)) // Reusing empty state loc
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return _MemberTile(member: member, theme: theme, isDark: isDark);
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

  const _MemberTile({required this.member, required this.theme, required this.isDark});

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
        trailing: IconButton(
          icon: const Icon(Icons.phone_in_talk_outlined, color: Colors.green),
          onPressed: () {
            // Logic to trigger phone call
          },
        ),
      ),
    );
  }
}