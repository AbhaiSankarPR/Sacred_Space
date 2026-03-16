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
  List<EventData> _events = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<EventData> fetchedEvents;
      if (_selectedFilter == "My Events") {
        fetchedEvents = await _authService.getMyRegistrations();
      } else {
        fetchedEvents = await _authService.getEvents(type: _selectedFilter.toLowerCase());
      }

      if (mounted) {
        setState(() {
          _events = fetchedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackBar("Failed to load events", isError: true);
    }
  }

  Future<void> _handleRSVP(EventData event) async {
    final loc = AppLocalizations.of(context)!;
    bool success = false;

    // 1. If already registered, confirm unregistration first
    if (event.isRegistered) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cancel Registration?"),
          content: Text("Do you want to unregister from '${event.title}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("UNREGISTER"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Call Unregister API
      setState(() => _isLoading = true);
      success = await _authService.unregisterFromEvent(event.id);
      
      if (success && mounted) {
        setState(() {
          event.isRegistered = false;
          event.currentAttendees--; // Update local count
          _isLoading = false;
        });
        _showSnackBar("Registration cancelled");
      }
    } 
    // 2. If not registered, perform registration
    else {
      // Check if event is full before attempting (safety check)
      if (event.maxSlots - event.currentAttendees <= 0) {
        _showSnackBar("This event is already full", isError: true);
        return;
      }

      setState(() => _isLoading = true);
      success = await _authService.registerForEvent(event.id);
      
      if (success && mounted) {
        setState(() {
          event.isRegistered = true;
          event.currentAttendees++; // Update local count
          _isLoading = false;
        });
        _showSnackBar(loc.rsvpUpdated);
      }
    }

    if (!success && mounted) {
      setState(() => _isLoading = false);
      _showSnackBar("Action failed. Please try again.", isError: true);
    }
  }

  Future<void> _handleDelete(String eventId) async {
    try {
      await _authService.deleteEvent(eventId);
      setState(() => _events.removeWhere((e) => e.id == eventId));
      _showSnackBar("Event deleted successfully");
    } catch (e) {
      _showSnackBar("Could not delete event", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateEventDialog() {
    final loc = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    final slotsController = TextEditingController(text: "100");
    DateTime? selectedDate;
    TimeOfDay? startTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                Text(loc.newBooking, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: InputDecoration(labelText: loc.eventType)),
                TextField(controller: locController, decoration: const InputDecoration(labelText: "Location")),
                TextField(controller: slotsController, decoration: const InputDecoration(labelText: "Max Slots"), keyboardType: TextInputType.number),
                TextField(controller: descController, decoration: InputDecoration(labelText: loc.describeEvent), maxLines: 2),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate == null ? loc.selectDate : DateFormat.yMMMd().format(selectedDate!)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setModalState(() => selectedDate = d);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(startTime == null ? "Select Time" : startTime!.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (t != null) setModalState(() => startTime = t);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D3A99),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && selectedDate != null && startTime != null) {
                      final fullDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startTime!.hour, startTime!.minute);

                      final success = await _authService.createEvent({
                        "title": titleController.text,
                        "description": descController.text,
                        "location": locController.text,
                        "date": fullDate.toUtc().toIso8601String(),
                        "maxSlots": int.tryParse(slotsController.text) ?? 100,
                      });

                      if (success && mounted) {
                        Navigator.pop(ctx);
                        _fetchEvents();
                      }
                    }
                  },
                  child: Text(loc.ok, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final user = _authService.currentUser;
    final bool isPriest = user?.role.toLowerCase() == 'priest';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.eventsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: AppDrawer(user: user!),
      floatingActionButton: isPriest
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF5D3A99),
              onPressed: _showCreateEventDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          _buildFilterTabs(loc, isPriest),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D3A99)))
                : RefreshIndicator(
                    onRefresh: _fetchEvents,
                    child: _events.isEmpty
                        ? ListView(children: [SizedBox(height: 200, child: Center(child: Text(loc.noBookingsFound)))])
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _events.length,
                            itemBuilder: (ctx, index) {
                              final event = _events[index];
                              return EventCard(
                                event: event,
                                isPriest: isPriest,
                                onRSVP: () => _handleRSVP(event),
                                onDelete: () => _handleDelete(event.id),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppLocalizations loc, bool isPriest) {
    final theme = Theme.of(context);
    
    // Dynamically generate the list of tabs
    final List<String> tabs = ["Upcoming", if (!isPriest) "My Events", "Past"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tabs.map((tab) => _FilterTab(
              label: tab == "Upcoming"
                  ? loc.upcoming
                  : (tab == "Past" ? loc.past : loc.myEvents),
              isSelected: _selectedFilter == tab,
              onTap: () {
                setState(() => _selectedFilter = tab);
                _fetchEvents();
              },
            )).toList(),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.isSelected, required this.onTap});

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
          color: isSelected ? const Color(0xFF5D3A99) : (isDark ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}