import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_service.dart';
import '../../auth/api_service.dart';
import '../../widgets/app_drawer.dart';

class Member {
  final String id, name, email, phone, houseName;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.houseName,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return Member(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: profile?['name'] ?? 'No Name',
      // Falls back to root phone if profile phone is missing
      phone: profile?['phone'] ?? (json['phone'] ?? 'No Phone'),
      houseName: profile?['houseName'] ?? 'No House Name',
    );
  }
}

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  String _searchQuery = "";
  List<Member> _allMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      setState(() => _isLoading = true);
      final response = await apiService.get('/priest/users');
      final List<dynamic> data = response.data;
      
      setState(() {
        _allMembers = data.map((m) => Member.fromJson(m)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Failed to load members: $e", isError: true);
    }
  }

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
      try {
        await apiService.delete('/priest/${member.id}');
        setState(() {
          _allMembers.removeWhere((m) => m.id == member.id);
        });
        _showSnackBar("Member removed successfully");
      } catch (e) {
        _showSnackBar("Delete failed: $e", isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'No Phone') return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showSnackBar("Could not launch dialer", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    // Security Gate
    if (user?.role.toLowerCase() != 'priest') {
      return Scaffold(body: Center(child: Text(loc.accessType("DENIED"))));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredMembers = _allMembers.where((m) {
      final query = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(query) || 
             m.houseName.toLowerCase().contains(query) ||
             m.email.toLowerCase().contains(query);
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
                hintText: "Search name, email or house...",
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchMembers,
                  child: filteredMembers.isEmpty
                      ? const Center(child: Text("No members found."))
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
                              onCall: () => _makePhoneCall(member.phone),
                            );
                          },
                        ),
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
  final VoidCallback onCall;

  const _MemberTile({
    required this.member, 
    required this.theme, 
    required this.isDark, 
    required this.onDelete,
    required this.onCall,
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
          radius: 25,
          backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF5D3A99), size: 28),
        ),
        title: Text(
          member.name, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // House Name
            Text(
              member.houseName, 
              style: TextStyle(
                color: member.houseName == "No House Name" ? Colors.grey : const Color(0xFF8E44AD), 
                fontSize: 13, 
                fontWeight: FontWeight.w600
              )
            ),
            const SizedBox(height: 6),
            // Clickable Phone Number
            if (member.phone != 'No Phone' && member.phone.isNotEmpty)
              InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      member.phone,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                "No Phone Number",
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
          tooltip: "Remove Member",
          onPressed: onDelete,
        ),
      ),
    );
  }
}