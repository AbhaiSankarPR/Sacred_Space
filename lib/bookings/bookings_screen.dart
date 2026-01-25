import 'package:flutter/material.dart';
// Ensure these match your actual file paths
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

// 1. Define a simple Data Model to hold booking info
class BookingData {
  final String title;
  final String date;
  final String time;
  final String location;
  final BookingStatus status;

  BookingData({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
  });
}

// 2. Convert to StatefulWidget to handle the filter state
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  // Current active filter
  String _selectedFilter = "All";

  // 3. The Data List (Move your hardcoded data here)
  final List<BookingData> _allBookings = [
    BookingData(
      title: "Marriage Ceremony",
      date: "12 Feb 2026",
      time: "10:00 AM - 2:00 PM",
      status: BookingStatus.approved,
      location: "Main Hall",
    ),
    BookingData(
      title: "Prayer Hall Request",
      date: "20 Feb 2026",
      time: "6:00 PM - 8:00 PM",
      status: BookingStatus.pending,
      location: "Community Center",
    ),
    BookingData(
      title: "Youth Meeting",
      date: "05 Jan 2026",
      time: "5:00 PM - 7:00 PM",
      status: BookingStatus.rejected,
      location: "Room 101",
    ),
  ];

  // 4. Logic to get only the items that match the filter
  List<BookingData> get _filteredBookings {
    if (_selectedFilter == "All") {
      return _allBookings;
    } else if (_selectedFilter == "Pending") {
      return _allBookings.where((b) => b.status == BookingStatus.pending).toList();
    } else if (_selectedFilter == "Approved") {
      return _allBookings.where((b) => b.status == BookingStatus.approved).toList();
    } else if (_selectedFilter == "Rejected") {
      return _allBookings.where((b) => b.status == BookingStatus.rejected).toList();
    }
    return _allBookings;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.newBooking),
        backgroundColor: const Color.fromARGB(255, 140, 124, 168),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Booking", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Filter Tabs ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: "All",
                    isSelected: _selectedFilter == "All",
                    onTap: () => setState(() => _selectedFilter = "All"),
                  ),
                  _FilterChip(
                    label: "Pending",
                    isSelected: _selectedFilter == "Pending",
                    onTap: () => setState(() => _selectedFilter = "Pending"),
                  ),
                  _FilterChip(
                    label: "Approved",
                    isSelected: _selectedFilter == "Approved",
                    onTap: () => setState(() => _selectedFilter = "Approved"),
                  ),
                  // Renamed "Past" to "Rejected" to match the data logic cleanly
                  _FilterChip(
                    label: "Rejected",
                    isSelected: _selectedFilter == "Rejected",
                    onTap: () => setState(() => _selectedFilter = "Rejected"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Dynamic Booking List ---
            // We use the getter _filteredBookings here
            if (_filteredBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text("No bookings found")),
              )
            else
              ..._filteredBookings.map((data) => BookingCard(
                    title: data.title,
                    date: data.date,
                    time: data.time,
                    status: data.status,
                    location: data.location,
                  )),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// --- KEEPING EVERYTHING BELOW THE SAME ---

enum BookingStatus { approved, pending, rejected }

class BookingCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String location;
  final BookingStatus status;

  const BookingCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case BookingStatus.approved:
        statusColor = Colors.green;
        statusText = "Approved";
        statusIcon = Icons.check_circle_outline;
        break;
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = "Pending";
        statusIcon = Icons.hourglass_empty;
        break;
      case BookingStatus.rejected:
        statusColor = Colors.red;
        statusText = "Rejected";
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_seat,
                    color: Color(0xFF5D3A99),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _IconTextRow(icon: Icons.access_time, text: time),
                      const SizedBox(height: 4),
                      _IconTextRow(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status == BookingStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Cancel Request"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconTextRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconTextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

// Updated FilterChip to accept onTap
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap; // Add onTap callback

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap, // Require it
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        // Call the onTap function when selected
        onSelected: (bool value) => onTap(), 
        selectedColor: const Color(0xFF5D3A99),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}