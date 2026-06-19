import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'complaint_model.dart';
import 'complaint_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _selectedFilter = "All";
  final ComplaintService _service = ComplaintService();
  late Future<List<Complaint>> _complaintsFuture;
  bool _isPriest = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _isPriest = user?.isOfficial ?? false;
    _refreshComplaints();
  }

  void _refreshComplaints() {
    setState(() {
      _complaintsFuture = _service.fetchComplaints(
        isPriest: _isPriest,
        status: _selectedFilter == "All" ? null : _selectedFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.complaints),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: !_isPriest
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.newComplaint);
                _refreshComplaints();
              },
              backgroundColor: const Color(0xFF5D3A99),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(loc.newComplaint),
            )
          : null,
      body: Column(
        children: [
          _buildFilterBar(loc, theme),
          Expanded(
            child: FutureBuilder<List<Complaint>>(
              future: _complaintsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        loc.errorOccurred,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final complaints = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async => _refreshComplaints(),
                  child: complaints.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Text(
                                loc.noComplaintsFound,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.hintColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            final complaint = complaints[index];
                            return _buildComplaintCard(complaint, theme, isDark);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations loc, ThemeData theme) {
    final filters = ["All", "Open", "In_Progress", "Resolved", "Closed"];
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: filters.map((f) {
              final isSelected = _selectedFilter == f;
              String labelText = '';
              if (f == 'All') labelText = loc.all;
              if (f == 'Open') labelText = loc.complaintStatusOpen;
              if (f == 'In_Progress') labelText = loc.complaintStatusInProgress;
              if (f == 'Resolved') labelText = loc.complaintStatusResolved;
              if (f == 'Closed') labelText = loc.complaintStatusClosed;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilter = f;
                    });
                    _refreshComplaints();
                  },
                  selectedColor: const Color(0xFF5D3A99),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF5D3A99) : Colors.transparent,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint, ThemeData theme, bool isDark) {
    final statusColor = _getStatusColor(complaint.status);
    final formattedDate = complaint.createdAt.toLocal().toString().substring(0, 16);
    final loc = AppLocalizations.of(context)!;

    String statusText = complaint.status;
    if (complaint.status.toUpperCase() == 'OPEN') statusText = loc.complaintStatusOpen;
    if (complaint.status.toUpperCase() == 'IN_PROGRESS') statusText = loc.complaintStatusInProgress;
    if (complaint.status.toUpperCase() == 'RESOLVED') statusText = loc.complaintStatusResolved;
    if (complaint.status.toUpperCase() == 'CLOSED') statusText = loc.complaintStatusClosed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.pushNamed(
              context,
              Routes.complaintDetail,
              arguments: complaint.id,
            );
            _refreshComplaints();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.description,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isPriest && complaint.user != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complaint.user!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.orange.shade700;
      case 'IN_PROGRESS':
        return Colors.blue.shade700;
      case 'RESOLVED':
        return Colors.green.shade700;
      case 'CLOSED':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }
}
