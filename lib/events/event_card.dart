import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './event_model.dart';

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

  // --- Show Details Popup ---
 void _showEventDetails(BuildContext context, AppLocalizations loc, ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  final timeRange = "${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, 
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIXED HEADER SECTION (Non-scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    if (isPriest)
                      Text(
                        "${event.registeredMembers.length} ${loc.registeredGoing}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D3A99)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),

          // SCROLLABLE BODY SECTION
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.calendar_today_rounded, loc.selectDate, DateFormat.yMMMMd().format(event.startTime)),
                  _buildDetailRow(Icons.access_time_filled_rounded, loc.startTime, timeRange),
                  _buildDetailRow(Icons.location_on_rounded, "Location", event.location),
                  
                  const SizedBox(height: 20),
                  Text(loc.describeEvent ?? "Description", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    event.description, 
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.4)
                  ),

                  // PRIEST ONLY: REGISTERED MEMBERS SECTION
                  if (isPriest) ...[
                    const Divider(height: 40),
                    const Text("Registered Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (event.registeredMembers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No members registered yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      )
                    else
                      ...event.registeredMembers.map((member) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF5D3A99).withValues(alpha: 0.1),
                              child: Text(
                                member.isNotEmpty ? member[0].toUpperCase() : "?",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF5D3A99)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              member,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ],
                        ),
                      )).toList(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // FIXED FOOTER BUTTON (Non-scrollable)
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3A99),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(loc.ok.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    ),
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
    final dayNumber = DateFormat('dd').format(event.startTime);
    final monthAbbr = DateFormat('MMM').format(event.startTime).toUpperCase();
    final timeRange = "${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material( // Wrap in Material for InkWell support
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventDetails(context, loc, theme),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DATE BOX ---
                    Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPastEvent ? Colors.grey.withValues(alpha: 0.1) : const Color(0xFF5D3A99).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isPastEvent ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF5D3A99).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dayNumber, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99), height: 1.1)),
                          Text(monthAbbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // --- DETAILS ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isPastEvent ? Colors.grey : (isDark ? Colors.white : Colors.black87)))),
                              if (isPriest)
                                IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(event.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 12),
                          Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // --- FOOTER ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99)),
                        const SizedBox(width: 6),
                        Text(timeRange, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isPastEvent ? Colors.grey : const Color(0xFF5D3A99))),
                      ],
                    ),
                    if (!isPriest && !isPastEvent)
                      TextButton.icon(
                        onPressed: onRSVP,
                        icon: Icon(event.isRegistered ? Icons.check_circle : Icons.add_circle_outline, size: 18, color: event.isRegistered ? Colors.green : const Color(0xFF5D3A99)),
                        label: Text(event.isRegistered ? loc.registeredGoing : loc.registerNow, style: TextStyle(color: event.isRegistered ? Colors.green : const Color(0xFF5D3A99), fontWeight: FontWeight.bold)),
                      )
                    else if (!isPriest && isPastEvent)
                      Text(loc.past.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}