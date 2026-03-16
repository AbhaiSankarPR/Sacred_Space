import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './event_model.dart';
import '../auth/auth_service.dart';

class EventCard extends StatelessWidget {
  final EventData event;
  final bool isPriest;
  final VoidCallback onRSVP;
  final VoidCallback onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.isPriest,
    required this.onRSVP,
    required this.onDelete,
  });

  // --- DELETE EVENT (PRIEST) ---
  void _showDeleteConfirmation(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(loc.deleteEvent),
        content: Text("Are you sure you want to permanently delete '${event.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(loc.ok, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UNREGISTER CONFIRMATION (MEMBER) ---
  void _showUnregisterConfirmation(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Unregister?"),
        content: Text("Do you want to cancel your registration for '${event.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRSVP(); // This will trigger the toggle logic in EventsScreen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("YES, UNREGISTER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) async {
    final isDark = theme.brightness == Brightness.dark;
    final eventTime = DateFormat.jm().format(event.startTime);
    final int remaining = event.remainingSlots;
    List<dynamic> attendees = [];

    if (isPriest) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
      try {
        attendees = await AuthService().getEventAttendees(event.id);
      } catch (e) {
        debugPrint("Error loading attendees: $e");
      } finally {
        if (context.mounted) Navigator.pop(context);
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge(
                          remaining > 0 ? loc.slotsAvailable(remaining) : "Event Full",
                          remaining > 0 ? Colors.blue : Colors.red,
                        ),
                        if (isPriest)
                          _buildBadge("${event.currentAttendees} ${loc.registeredGoing}", const Color(0xFF5D3A99)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.calendar_today_rounded, loc.selectDate, DateFormat.yMMMMd().format(event.startTime)),
                    _buildDetailRow(Icons.access_time_filled_rounded, loc.startTime, eventTime),
                    _buildDetailRow(Icons.location_on_rounded, "Location", event.location),
                    const SizedBox(height: 24),
                    Text(loc.describeEvent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(event.description, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.4)),
                    
                    if (isPriest) ...[
                      const SizedBox(height: 32),
                      const Text("Participants List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      if (attendees.isEmpty)
                        const Center(child: Text("No one has registered yet.", style: TextStyle(color: Colors.grey)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: attendees.length,
                          itemBuilder: (context, index) {
                            final userObj = attendees[index]['user'];
                            final String name = userObj['profile']?['name'] ?? "Unknown Member";
                            final String email = userObj['email'] ?? "No email";
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF5D3A99),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                            );
                          },
                        ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(loc.ok.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5D3A99)),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isPastEvent = event.startTime.isBefore(DateTime.now());
    final timeRange = DateFormat.jm().format(event.startTime);
    final int remaining = event.remainingSlots;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventDetails(context, loc, theme),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPastEvent ? Colors.grey.withValues(alpha: 0.1) : const Color(0xFF5D3A99).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isPastEvent ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF5D3A99).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(DateFormat('dd').format(event.startTime), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99))),
                          Text(DateFormat('MMM').format(event.startTime).toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPastEvent ? Colors.grey : Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isPastEvent ? Colors.grey : null))),
                              if (isPriest)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _showDeleteConfirmation(context, loc),
                                ),
                            ],
                          ),
                          Text(event.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isPastEvent ? Colors.grey : null)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99)),
                        const SizedBox(width: 4),
                        Text(timeRange, style: TextStyle(color: isPastEvent ? Colors.grey : null)),
                      ],
                    ),
                    if (!isPriest && !isPastEvent)
                      TextButton.icon(
                        // If registered, clicking triggers unregistration logic.
                        // If not registered, disable only if FULL.
                        onPressed: event.isRegistered 
                            ? () => _showUnregisterConfirmation(context, loc)
                            : (remaining <= 0 ? null : onRSVP),
                        icon: Icon(
                          event.isRegistered ? Icons.check_circle : Icons.add_circle_outline,
                          color: event.isRegistered ? Colors.green : (remaining <= 0 ? Colors.grey : const Color(0xFF5D3A99)),
                        ),
                        label: Text(
                          event.isRegistered ? loc.registeredGoing : (remaining <= 0 ? "FULL" : loc.registerNow),
                          style: TextStyle(
                            color: event.isRegistered ? Colors.green : (remaining <= 0 ? Colors.grey : const Color(0xFF5D3A99)),
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    else if (!isPriest && isPastEvent)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(loc.past.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}