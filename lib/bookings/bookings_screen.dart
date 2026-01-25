import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

// 1. Data Model
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

// 2. StatefulWidget
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = "All";

  // 3. Data List
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

  // 4. Filter Logic
  List<BookingData> get _filteredBookings {
    if (_selectedFilter == "All") return _allBookings;
    if (_selectedFilter == "Pending") return _allBookings.where((b) => b.status == BookingStatus.pending).toList();
    if (_selectedFilter == "Approved") return _allBookings.where((b) => b.status == BookingStatus.approved).toList();
    if (_selectedFilter == "Rejected") return _allBookings.where((b) => b.status == BookingStatus.rejected).toList();
    return _allBookings;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Access dynamic theme
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic Background
      appBar: AppBar(
        title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.newBooking),
        backgroundColor: const Color(0xFF5D3A99),
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
                  _FilterChip(
                    label: "Rejected",
                    isSelected: _selectedFilter == "Rejected",
                    onTap: () => setState(() => _selectedFilter = "Rejected"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Booking List ---
            if (_filteredBookings.isEmpty)
               Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "No bookings found", 
                    style: TextStyle(color: theme.hintColor),
                  ),
                ),
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

// --- CONSTANTS ---
enum BookingStatus { approved, pending, rejected }

// --- WIDGETS ---

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
    // Dynamic Colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        color: theme.cardColor, // Dynamic Card Background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), // Darker shadow in dark mode
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.2 : 0.1), // Slightly more opaque in dark mode
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    color: isDark ? Colors.white70 : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _IconTextRow(icon: Icons.access_time, text: time),
                      const SizedBox(height: 4),
                      _IconTextRow(icon: Icons.location_on_outlined, text: location),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
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
    // Dynamic text color for subtitles
    final color = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white60 
        : Colors.grey;

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) => onTap(),
        selectedColor: const Color(0xFF5D3A99),
        checkmarkColor: Colors.white,
        
        // Dynamic Label Style
        labelStyle: TextStyle(
          color: isSelected 
              ? Colors.white 
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        
        // Dynamic Background
        backgroundColor: theme.cardColor,
        
        // Dynamic Border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
    );
  }
}