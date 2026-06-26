import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../settings/family_request_model.dart';
import 'member_model.dart';
import 'member_service.dart';

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final MemberService _memberService = MemberService();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _searchQuery = "";
  List<Member> _allMembers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchMembers(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMembers(isLoadMore: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _fetchMembers(isRefresh: true);
    });
  }

  Future<void> _fetchMembers({
    bool isRefresh = false,
    bool isLoadMore = false,
  }) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    } else if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    }

    try {
      final int pageToFetch = isLoadMore ? _currentPage + 1 : 1;

      final response = await _memberService.fetchMembers(
        page: pageToFetch,
        limit: _limit,
        searchQuery: _searchQuery,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _allMembers.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _allMembers = response.data;
            _currentPage = 1;
          }
          _hasMore = response.meta.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent <= 0 &&
              _hasMore &&
              !_isLoading &&
              !_isLoadingMore) {
            _fetchMembers(isLoadMore: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showSnackBar("Failed to load members: $e", isError: true);
      }
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
        await _memberService.removeMember(member.id);
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

  void _showFamilyConnectionsSheet(Member member) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                        child: const Icon(Icons.family_restroom, color: Color(0xFF5D3A99), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Family Connections",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<FamilyConnection>>(
                      future: AuthService().getMemberFamilyConnections(member.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  "Failed to load details: ${snapshot.error}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        } else {
                          final connections = snapshot.data ?? [];
                          if (connections.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.family_restroom,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No family connections linked.",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: connections.length,
                            itemBuilder: (context, index) {
                              final connection = connections[index];
                              return _buildConnectionCard(connection, theme, isDark);
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConnectionCard(
    FamilyConnection connection,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showConnectionDetails(connection),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
          backgroundImage: connection.relatedUser.profile.profilePicUrl != null && connection.relatedUser.profile.profilePicUrl!.isNotEmpty
              ? NetworkImage(connection.relatedUser.profile.profilePicUrl!)
              : (connection.relatedUser.profilePicUrl != null && connection.relatedUser.profilePicUrl!.isNotEmpty
                  ? NetworkImage(connection.relatedUser.profilePicUrl!)
                  : null),
          child: (connection.relatedUser.profile.profilePicUrl == null || connection.relatedUser.profile.profilePicUrl!.isEmpty) &&
                 (connection.relatedUser.profilePicUrl == null || connection.relatedUser.profilePicUrl!.isEmpty)
              ? const Icon(Icons.person, color: Color(0xFF5D3A99))
              : null,
        ),
        title: Text(
          connection.relatedUser.profile.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          connection.relation,
          style: TextStyle(
            color: const Color(0xFF5D3A99).withOpacity(0.8),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  void _showConnectionDetails(FamilyConnection connection) {
    final profile = connection.relatedUser.profile;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                backgroundImage: connection.relatedUser.profile.profilePicUrl != null && connection.relatedUser.profile.profilePicUrl!.isNotEmpty
                    ? NetworkImage(connection.relatedUser.profile.profilePicUrl!)
                    : (connection.relatedUser.profilePicUrl != null && connection.relatedUser.profilePicUrl!.isNotEmpty
                        ? NetworkImage(connection.relatedUser.profilePicUrl!)
                        : null),
                child: (connection.relatedUser.profile.profilePicUrl == null || connection.relatedUser.profile.profilePicUrl!.isEmpty) &&
                       (connection.relatedUser.profilePicUrl == null || connection.relatedUser.profilePicUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF5D3A99),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                connection.relation,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF5D3A99).withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.wc,
                loc.gender,
                profile.gender ?? "N/A",
              ),
              _buildDetailRow(
                Icons.cake,
                loc.date,
                profile.dob != null && profile.dob!.isNotEmpty
                    ? profile.dob!.split('T')[0]
                    : "N/A",
              ),
              _buildDetailRow(
                Icons.home_outlined,
                "House Name",
                profile.houseName ?? "N/A",
              ),
              _buildDetailRow(
                Icons.numbers,
                "House Number",
                profile.houseNumber ?? "N/A",
              ),
              _buildDetailRow(
                Icons.location_on_outlined,
                "Address",
                profile.permanentAddress ?? "N/A",
              ),
              _buildDetailRow(
                Icons.apartment,
                "Residence Type",
                profile.residenceType ?? "N/A",
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D3A99).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF5D3A99)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              onChanged: _onSearchChanged,
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
            child: _isLoading && _allMembers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _fetchMembers(isRefresh: true),
                  child: _allMembers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: const Center(
                                child: Text("No members found."),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _allMembers.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _allMembers.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(color: Color(0xFF5D3A99)),
                                ),
                              );
                            }
                            final member = _allMembers[index];
                            return _MemberTile(
                              member: member, 
                              theme: theme, 
                              isDark: isDark,
                              onDelete: () => _removeMember(member),
                              onCall: () => _makePhoneCall(member.phone),
                              onTap: () => _showFamilyConnectionsSheet(member),
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
  final VoidCallback onTap;

  const _MemberTile({
    required this.member, 
    required this.theme, 
    required this.isDark, 
    required this.onDelete,
    required this.onCall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
          backgroundImage: member.profilePicUrl != null && member.profilePicUrl!.isNotEmpty
              ? NetworkImage(member.profilePicUrl!)
              : null,
          child: member.profilePicUrl == null || member.profilePicUrl!.isEmpty
              ? const Icon(Icons.person, color: Color(0xFF5D3A99), size: 28)
              : null,
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
