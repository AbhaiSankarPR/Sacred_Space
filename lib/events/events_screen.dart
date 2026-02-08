import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

// 1. Data Model
class EventData {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String category;
  bool isRegistered;

  EventData({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.category,
    this.isRegistered = false,
  });
}

// 2. Stateful Screen
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedFilter = "Upcoming";

  final List<EventData> _allEvents = [
    EventData(
      id: '1',
      title: "Annual Charity Gala",
      dateTime: DateTime(2026, 3, 15, 18, 0),
      location: "Grand Ballroom",
      category: "Community",
      isRegistered: true,
    ),
    EventData(
      id: '2',
      title: "Sunday Worship Service",
      dateTime: DateTime(2026, 2, 12, 9, 0),
      location: "Main Sanctuary",
      category: "Worship",
      isRegistered: false,
    ),
    EventData(
      id: '3',
      title: "Youth Music Night",
      dateTime: DateTime(2026, 2, 20, 19, 30),
      location: "Youth Hall",
      category: "Youth",
      isRegistered: false,
    ),
    EventData(
      id: '4',
      title: "Past Leadership Summit",
      dateTime: DateTime(2025, 12, 10, 10, 0),
      location: "Conference Room B",
      category: "Leadership",
      isRegistered: false,
    ),
  ];

  List<EventData> get _filteredEvents {
    final now = DateTime.now();
    if (_selectedFilter == "Upcoming") {
      return _allEvents.where((e) => e.dateTime.isAfter(now)).toList();
    } else if (_selectedFilter == "My Events") {
      return _allEvents.where((e) => e.isRegistered && e.dateTime.isAfter(now)).toList();
    } else if (_selectedFilter == "Past") {
      return _allEvents.where((e) => e.dateTime.isBefore(now)).toList();
    }
    return _allEvents;
  }

  void _toggleRegistration(String id) {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      final event = _allEvents.firstWhere((e) => e.id == id);
      event.isRegistered = !event.isRegistered;
    });
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.rsvpUpdated)),
    );
  }

  String _getLocalizedStatus(AppLocalizations loc) {
    if (_selectedFilter == "Upcoming") return loc.upcoming;
    if (_selectedFilter == "Past") return loc.past;
    return loc.myEvents;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.eventsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      body: Column(
        children: [
          // --- Filter Tabs ---
          Container(
            color: theme.cardColor,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: loc.upcoming,
                    isSelected: _selectedFilter == "Upcoming",
                    onTap: () => setState(() => _selectedFilter = "Upcoming"),
                  ),
                  _FilterTab(
                    label: loc.myEvents,
                    isSelected: _selectedFilter == "My Events",
                    onTap: () => setState(() => _selectedFilter = "My Events"),
                  ),
                  _FilterTab(
                    label: loc.past,
                    isSelected: _selectedFilter == "Past",
                    onTap: () => setState(() => _selectedFilter = "Past"),
                  ),
                ],
              ),
            ),
          ),

          // --- Event List ---
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: theme.hintColor),
                        const SizedBox(height: 16),
                        Text(
                          loc.noEventsFound(_getLocalizedStatus(loc)),
                          style: TextStyle(color: theme.hintColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (ctx, index) {
                      final event = _filteredEvents[index];
                      return _EventCard(
                        event: event,
                        onRSVP: () => _toggleRegistration(event.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 3. UI Components

class _EventCard extends StatelessWidget {
  final EventData event;
  final VoidCallback onRSVP;

  const _EventCard({required this.event, required this.onRSVP});

  String _getLocalizedMonth(int month, AppLocalizations loc) {
    final months = [
      loc.jan, loc.feb, loc.mar, loc.apr, loc.may, loc.jun,
      loc.jul, loc.aug, loc.sep, loc.oct, loc.nov, loc.dec
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    final month = _getLocalizedMonth(event.dateTime.month, loc);
    final day = event.dateTime.day.toString();
    final timeStr = "${event.dateTime.hour > 12 ? event.dateTime.hour - 12 : event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')} ${event.dateTime.hour >= 12 ? 'PM' : 'AM'}";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3A99).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: Colors.white12) : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? const Color(0xFF9B59B6) : const Color(0xFF5D3A99)
                        ),
                      ),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: isDark ? const Color(0xFF9B59B6) : const Color(0xFF5D3A99)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.orange[800]
                          ),
                        ),
                      ),
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: subTextColor),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(fontSize: 13, color: subTextColor)),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: subTextColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location, 
                              style: TextStyle(fontSize: 13, color: subTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          InkWell(
            onTap: onRSVP,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: event.isRegistered 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    event.isRegistered ? Icons.check_circle : Icons.person_add_alt_1,
                    size: 18,
                    color: event.isRegistered 
                        ? Colors.green 
                        : (isDark ? const Color(0xFF9B59B6) : const Color(0xFF5D3A99)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.isRegistered ? loc.registeredGoing : loc.registerNow,
                    style: TextStyle(
                      color: event.isRegistered 
                          ? Colors.green 
                          : (isDark ? const Color(0xFF9B59B6) : const Color(0xFF5D3A99)),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF5D3A99) 
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : (isDark ? Colors.white70 : Colors.grey[700]),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}