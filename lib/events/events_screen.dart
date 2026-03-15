import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';
import 'event_model.dart';
import './event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = "Upcoming";
  final List<EventData> _allEvents = [
    // 1. UPCOMING EVENT (Member is NOT registered)
    EventData(
      id: 'test-1',
      title: "Easter Sunday Service",
      description:
          "Join us for a special morning worship service celebrating the resurrection. Choir performance starts at 8:45 AM.",
      startTime: DateTime(2026, 4, 5, 9, 0),
      endTime: DateTime(2026, 4, 5, 11, 30),
      location: "Main Sanctuary",
      category: "Worship",
      isRegistered: false,
      registeredMembers: ["Naveen", "Akhil", "Jerin", "Sneha"], // Test data
    ),

    // 2. REGISTERED EVENT (Upcoming)
    EventData(
      id: 'test-2',
      title: "Parish Youth Meetup",
      description:
          "Monthly gathering for the youth ministry. Games, music, and refreshment followed by a short meditation session.",
      startTime: DateTime(2026, 3, 25, 17, 30),
      endTime: DateTime(2026, 3, 25, 20, 0),
      location: "Youth Hall",
      category: "Youth",
      isRegistered: true, // This will show up in "My Events"
    ),

    // 3. PAST EVENT
    EventData(
      id: 'test-3',
      title: "Ash Wednesday Mass",
      description: "Lenten season commencement with the imposition of ashes.",
      startTime: DateTime(2026, 2, 18, 18, 0),
      endTime: DateTime(2026, 2, 18, 19, 30),
      location: "Chapel",
      category: "Worship",
      isRegistered: false, // This will show up in "Past"
    ),

    // 4. ANOTHER UPCOMING (For scroll testing)
    EventData(
      id: 'test-4',
      title: "Community Outreach Program",
      description:
          "Distribution of food packets and basic necessities to the neighborhood. Volunteers are requested to arrive 30 mins early.",
      startTime: DateTime(2026, 5, 10, 10, 0),
      endTime: DateTime(2026, 5, 10, 16, 0),
      location: "Church Grounds",
      category: "Charity",
      isRegistered: false,
    ),
  ];
  List<EventData> get _filteredEvents {
    final now = DateTime.now();
    if (_selectedFilter == "Upcoming") {
      return _allEvents.where((e) => e.startTime.isAfter(now)).toList();
    } else if (_selectedFilter == "My Events") {
      return _allEvents
          .where((e) => e.isRegistered && e.startTime.isAfter(now))
          .toList();
    } else if (_selectedFilter == "Past") {
      return _allEvents.where((e) => e.startTime.isBefore(now)).toList();
    }
    return _allEvents;
  }

  void _showCreateEventDialog() {
    final loc = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.newBooking,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(labelText: loc.eventType),
                        ),
                        TextField(
                          controller: locController,
                          decoration: const InputDecoration(
                            labelText: "Location",
                          ),
                        ),
                        TextField(
                          controller: descController,
                          decoration: InputDecoration(
                            labelText: loc.describeEvent,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            selectedDate == null
                                ? loc.selectDate
                                : DateFormat.yMMMd().format(selectedDate!),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (d != null)
                              setModalState(() => selectedDate = d);
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  startTime == null
                                      ? "Start"
                                      : startTime!.format(context),
                                ),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null)
                                    setModalState(() => startTime = t);
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  endTime == null
                                      ? "End"
                                      : endTime!.format(context),
                                ),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null)
                                    setModalState(() => endTime = t);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D3A99),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (titleController.text.isNotEmpty &&
                                selectedDate != null &&
                                startTime != null &&
                                endTime != null) {
                              setState(() {
                                _allEvents.add(
                                  EventData(
                                    id: DateTime.now().toString(),
                                    title: titleController.text,
                                    description: descController.text,
                                    location: locController.text,
                                    startTime: DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      startTime!.hour,
                                      startTime!.minute,
                                    ),
                                    endTime: DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      endTime!.hour,
                                      endTime!.minute,
                                    ),
                                    category: "Church Event",
                                  ),
                                );
                              });
                              Navigator.pop(ctx);
                            }
                          },
                          child: Text(
                            loc.ok,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final bool isPriest = user?.role.toLowerCase() == 'priest';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.eventsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user!),
      floatingActionButton:
          isPriest
              ? FloatingActionButton(
                backgroundColor: const Color(0xFF5D3A99),
                onPressed: _showCreateEventDialog,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: Column(
        children: [
          _buildFilterTabs(loc),
          Expanded(
            child:
                _filteredEvents.isEmpty
                    ? Center(child: Text(loc.noBookingsFound))
                    : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (ctx, index) {
                        final event = _filteredEvents[index];
                        return EventCard(
                          event: event,
                          isPriest: isPriest,
                          onRSVP: () {
                            setState(
                              () => event.isRegistered = !event.isRegistered,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.rsvpUpdated)),
                            );
                          },
                          onDelete:
                              () => setState(
                                () => _allEvents.removeWhere(
                                  (e) => e.id == event.id,
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

 Widget _buildFilterTabs(AppLocalizations loc) {
  final theme = Theme.of(context);
  final tabs = ["Upcoming", "My Events", "Past"];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 12),
    // Use cardColor to automatically switch between white (Light) and dark grey (Dark)
    color: theme.cardColor, 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tabs.map((tab) => _FilterTab(
        label: tab == "Upcoming"
            ? loc.upcoming
            : (tab == "Past" ? loc.past : loc.myEvents),
        isSelected: _selectedFilter == tab,
        onTap: () => setState(() => _selectedFilter = tab),
      )).toList(),
    ),
  );
}
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5D3A99)
              // In dark mode, we use a subtle white opacity instead of light grey
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}