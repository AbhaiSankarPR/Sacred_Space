import 'package:flutter/material.dart';
// Ensure these match your actual file paths
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

// 1. Data Model
class EventData {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String category; // e.g., "Youth", "Worship", "Community"
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

  // Mock Data
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

  // Logic to filter the list
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

  // Toggle RSVP
  void _toggleRegistration(String id) {
    setState(() {
      final event = _allEvents.firstWhere((e) => e.id == id);
      event.isRegistered = !event.isRegistered;
    });
    
    // Optional: Show snackbar feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("RSVP status updated!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Safety check
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Church Events", style: TextStyle(fontWeight: FontWeight.bold)),
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterTab(
                    label: "Upcoming",
                    isSelected: _selectedFilter == "Upcoming",
                    onTap: () => setState(() => _selectedFilter = "Upcoming"),
                  ),
                  _FilterTab(
                    label: "My Events",
                    isSelected: _selectedFilter == "My Events",
                    onTap: () => setState(() => _selectedFilter = "My Events"),
                  ),
                  _FilterTab(
                    label: "Past",
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
                        Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "No $_selectedFilter events found",
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    // Formatting Date
    final months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    final month = months[event.dateTime.month - 1];
    final day = event.dateTime.day.toString();
    
    // Formatting Time
    final timeStr = "${event.dateTime.hour > 12 ? event.dateTime.hour - 12 : event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')} ${event.dateTime.hour >= 12 ? 'PM' : 'AM'}";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Date Badge + Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D3A99).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF5D3A99)
                        ),
                      ),
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF5D3A99)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                        ),
                      ),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location, 
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

          // Divider
          const Divider(height: 1, color: Colors.black12),

          // Bottom Action Bar
          InkWell(
            onTap: onRSVP,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: event.isRegistered ? Colors.green.withOpacity(0.1) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    event.isRegistered ? Icons.check_circle : Icons.person_add_alt_1,
                    size: 18,
                    color: event.isRegistered ? Colors.green : const Color(0xFF5D3A99),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.isRegistered ? "REGISTERED - GOING" : "REGISTER NOW",
                    style: TextStyle(
                      color: event.isRegistered ? Colors.green : const Color(0xFF5D3A99),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D3A99) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}