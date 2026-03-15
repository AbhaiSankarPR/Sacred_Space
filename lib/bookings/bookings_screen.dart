import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'booking_model.dart';
import 'booking_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = "All";
  final BookingService _service = BookingService();
  late Future<List<BookingData>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  void _refreshBookings() {
    setState(() {
      _bookingsFuture = _service.fetchBookings();
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

    final bool isPriest = user.role.toLowerCase() == 'priest';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isPriest ? loc.manageRequests : loc.myBookings),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: !isPriest
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.newBooking);
                _refreshBookings();
              },
              backgroundColor: const Color(0xFF5D3A99),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(loc.newBooking),
            )
          : null,
      body: Column(
        children: [
          _buildFilterBar(loc, theme),
          Expanded(
            child: FutureBuilder<List<BookingData>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text(loc.errorOccurred));
                }

                final allBookings = snapshot.data ?? [];
                final filteredBookings = _selectedFilter == "All"
                    ? allBookings
                    : allBookings
                        .where((b) =>
                            b.status.name.toLowerCase() ==
                            _selectedFilter.toLowerCase())
                        .toList();

                return RefreshIndicator(
                  onRefresh: () async => _refreshBookings(),
                  child: filteredBookings.isEmpty
                      ? Center(child: Text(loc.noBookingsFound))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) => BookingCard(
                            data: filteredBookings[index],
                            isPriest: isPriest,
                            onRefresh: _refreshBookings,
                          ),
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
    final filters = ["All", "Pending", "Approved", "Rejected"];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    f == "All"
                        ? loc.all
                        : (f == "Pending"
                            ? loc.pending
                            : (f == "Approved" ? loc.approved : loc.rejected)),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedFilter = f),
                selectedColor: const Color(0xFF5D3A99),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                side: BorderSide(color: isSelected ? const Color(0xFF5D3A99) : Colors.transparent),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final BookingData data;
  final bool isPriest;
  final VoidCallback onRefresh;

  const BookingCard({
    super.key,
    required this.data,
    required this.isPriest,
    required this.onRefresh,
  });

  // --- Handle Approval with Conflict Check ---
  void _handlePriestApproval(BuildContext context, AppLocalizations loc) async {
    // Show a small loading indicator while checking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99))),
    );

    try {
      final conflicts = await BookingService().checkConflicts(data.id);
      
      if (context.mounted) Navigator.pop(context); // Remove loading indicator

      if (conflicts.isNotEmpty) {
        if (context.mounted) _showConflictDialog(context, conflicts, loc);
      } else {
        if (context.mounted) _update(context, "APPROVED");
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.errorOccurred)));
      }
    }
  }

  void _showConflictDialog(BuildContext context, List<BookingData> conflicts, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(loc.conflictDetected ?? "Schedule Conflict"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("The following events overlap with this request:"),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conflicts.length,
                  itemBuilder: (context, index) {
                    final conflict = conflicts[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.circle,
                        size: 10,
                        color: conflict.status == BookingStatus.approved ? Colors.green : Colors.orange,
                      ),
                      title: Text(conflict.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "${DateFormat.jm().format(conflict.startTime.toLocal())} (${conflict.status.name})",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancelRequest),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _update(context, "APPROVED");
            },
            child: const Text("Approve Anyway"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isRejected = data.status == BookingStatus.rejected;
    final Color statusColor =
        data.status == BookingStatus.approved
            ? Colors.green
            : (isRejected ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(statusColor, loc),
          InkWell(
            onTap: () => _showDetailsSheet(context, loc, theme),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateIcon(data.startTime, context),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: theme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "${DateFormat.jm().format(data.startTime.toLocal())} - ${DateFormat.jm().format(data.endTime.toLocal())}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isPriest
                                  ? "${loc.requestedBy}: ${data.requestedBy}"
                                  : data.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRejected && data.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.rejected.toUpperCase(),
                            style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.rejectionReason!,
                            style: TextStyle(color: Colors.red[900], fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (data.status == BookingStatus.pending) ...[
            const Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: isPriest
                  ? _buildPriestActions(context, loc)
                  : _buildMemberActions(loc, theme),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, AppLocalizations loc, ThemeData theme) {
    final bool isRejected = data.status == BookingStatus.rejected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(data.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _buildStatusBadge(data.status, loc),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, loc.selectDate, DateFormat.yMMMMd().format(data.startTime)),
            _buildDetailRow(Icons.access_time, loc.startTime, DateFormat.jm().format(data.startTime.toLocal())),
            _buildDetailRow(Icons.update, loc.endTime, DateFormat.jm().format(data.endTime.toLocal())),
            const Divider(height: 32),
            Text(loc.purposeNotes, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(data.description, style: TextStyle(color: Colors.grey[800], height: 1.5)),
            if (isRejected && data.rejectionReason != null) ...[
              const SizedBox(height: 20),
              Text(loc.rejected.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 4),
              Text(data.rejectionReason!, style: TextStyle(color: Colors.red[900], fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.ok),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status, AppLocalizations loc) {
    final color = status == BookingStatus.approved ? Colors.green : (status == BookingStatus.rejected ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5D3A99)),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Color color, AppLocalizations loc) {
    String statusText = data.status == BookingStatus.approved ? loc.approved : (data.status == BookingStatus.rejected ? loc.rejected : loc.pending);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("#${data.id.substring(0, 8).toUpperCase()}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(statusText.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateIcon(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5D3A99).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5D3A99).withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(date.day.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF5D3A99))),
          Text(DateFormat('MMM', locale).format(date).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D3A99))),
        ],
      ),
    );
  }

  Widget _buildPriestActions(BuildContext context, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _handlePriestApproval(context, loc),
            child: Text(loc.approve, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showRejectionDialog(context, loc),
            child: Text(loc.reject, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showRejectionDialog(BuildContext context, AppLocalizations loc) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reject),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: loc.describeEvent, border: const OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancelRequest)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(ctx);
                _update(context, "REJECTED", reason: reasonController.text);
              }
            },
            child: Text(loc.reject),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActions(AppLocalizations loc, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () {}, // Implementation for cancellation
          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
          label: Text(loc.cancelRequest, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: Colors.red.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  void _update(BuildContext context, String status, {String? reason}) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await BookingService().updateBookingStatus(data.id, status, reason: reason);
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.errorOccurred)));
      }
    }
  }
}