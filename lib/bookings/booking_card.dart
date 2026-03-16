import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'booking_model.dart';
import 'booking_service.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99))),
    );

    try {
      final conflicts = await BookingService().checkConflicts(data.id);
      if (context.mounted) Navigator.pop(context);

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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(loc.conflictDetected ?? "Schedule Conflict", 
              style: TextStyle(color: theme.textTheme.titleLarge?.color)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("The following events overlap with this request:",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
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
                      title: Text(conflict.title, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      subtitle: Text(
                        "${DateFormat.jm().format(conflict.startTime.toLocal())} (${conflict.status.name})",
                        style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancelRequest)),
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

  // --- Handle Cancel (Member) ---
  void _handleCancel(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.cancelRequest),
        content: const Text("Are you sure you want to cancel this booking request? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.ok),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                await BookingService().cancelBooking(data.id);
                onRefresh(); // Refresh the list
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.errorOccurred)),
                  );
                }
              }
            },
            child: const Text("Confirm Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isRejected = data.status == BookingStatus.rejected;
    final Color statusColor = data.status == BookingStatus.approved ? Colors.green : (isRejected ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(statusColor, loc, theme),
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
                      _buildDateIcon(data.startTime, context, theme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: theme.primaryColor),
                                const SizedBox(width: 4),
                                Text("${DateFormat.jm().format(data.startTime.toLocal())} - ${DateFormat.jm().format(data.endTime.toLocal())}",
                                    style: TextStyle(fontSize: 13, color: theme.primaryColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(isPriest ? "${loc.requestedBy}: ${data.requestedBy}" : data.description,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), height: 1.3)),
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
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.rejected.toUpperCase(), style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(data.rejectionReason!, style: TextStyle(color: isDark ? Colors.red[200] : Colors.red[900], fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (data.status == BookingStatus.pending) ...[
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: isPriest ? _buildPriestActions(context, loc, theme) : _buildMemberActions(context, loc, theme),
            ),
          ] else const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, AppLocalizations loc, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(data.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                _buildStatusBadge(data.status, loc),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, loc.selectDate, DateFormat.yMMMMd().format(data.startTime), theme),
            _buildDetailRow(Icons.access_time, loc.startTime, DateFormat.jm().format(data.startTime.toLocal()), theme),
            _buildDetailRow(Icons.update, loc.endTime, DateFormat.jm().format(data.endTime.toLocal()), theme),
            Divider(height: 32, color: theme.dividerColor),
            Text(loc.purposeNotes, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
            const SizedBox(height: 8),
            Text(data.description, style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8), height: 1.5)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D3A99), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5D3A99)),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color))),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Color color, AppLocalizations loc, ThemeData theme) {
    String statusText = data.status == BookingStatus.approved ? loc.approved : (data.status == BookingStatus.rejected ? loc.rejected : loc.pending);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("#${data.id.substring(0, 8).toUpperCase()}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)), child: Text(statusText.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildDateIcon(DateTime date, BuildContext context, ThemeData theme) {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      width: 50, padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF5D3A99).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF5D3A99).withValues(alpha: 0.1))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(date.day.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF5D3A99))),
          Text(DateFormat('MMM', locale).format(date).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D3A99))),
        ],
      ),
    );
  }

  Widget _buildPriestActions(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => _handlePriestApproval(context, loc),
            child: Text(loc.approve, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => _showRejectionDialog(context, loc),
            child: Text(loc.reject, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showRejectionDialog(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(loc.reject, style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        content: TextField(
          controller: reasonController,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(hintText: loc.describeEvent, hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color), border: const OutlineInputBorder()),
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

  Widget _buildMemberActions(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => _handleCancel(context, loc),
          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
          label: Text(
            loc.cancelRequest, 
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16), 
            backgroundColor: Colors.red.withValues(alpha: 0.05), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
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