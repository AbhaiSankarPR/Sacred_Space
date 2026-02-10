import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';

// --- DATA MODELS ---
enum BookingStatus { approved, pending, rejected }

class BookingData {
  final String id;
  final String title;
  final String requestedBy; 
  final String date;
  final String time;
  final String location;
  final BookingStatus status;

  BookingData({
    required this.id, required this.title, required this.requestedBy,
    required this.date, required this.time, required this.location,
    required this.status,
  });
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isPriest = user.role.toLowerCase() == 'priest';
    final theme = Theme.of(context);

    // Mock Data - Connect to your API via AuthService in production
    final List<BookingData> allBookings = [
      BookingData(
        id: "BK-101",
        title: loc.marriageCeremony,
        requestedBy: "Naveen",
        date: "12 Feb 2026",
        time: "10:00 AM - 02:00 PM",
        status: BookingStatus.approved,
        location: "Main Sanctuary",
      ),
      BookingData(
        id: "BK-102",
        title: loc.prayerHallRequest,
        requestedBy: "Anish",
        date: "20 Feb 2026",
        time: "06:00 PM - 08:00 PM",
        status: BookingStatus.pending,
        location: "Community Hall",
      ),
    ];

    final filteredBookings = _selectedFilter == "All" 
        ? allBookings 
        : allBookings.where((b) => b.status.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isPriest ? loc.manageRequests : loc.myBookings, 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: !isPriest ? FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.newBooking),
        backgroundColor: const Color(0xFF5D3A99),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(loc.newBooking),
      ) : null,
      body: Column(
        children: [
          _buildFilterBar(loc, theme),
          Expanded(
            child: filteredBookings.isEmpty
                ? Center(child: Text(loc.noBookingsFound))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) => BookingCard(
                      data: filteredBookings[index],
                      isPriest: isPriest,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppLocalizations loc, ThemeData theme) {
    final filters = ["All", "Pending", "Approved", "Rejected"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f == "All" ? loc.all : (f == "Pending" ? loc.pending : (f == "Approved" ? loc.approved : loc.rejected))),
            selected: _selectedFilter == f,
            onSelected: (val) => setState(() => _selectedFilter = f),
            selectedColor: const Color(0xFF5D3A99),
            labelStyle: TextStyle(color: _selectedFilter == f ? Colors.white : Colors.black),
          ),
        )).toList(),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final BookingData data;
  final bool isPriest;

  const BookingCard({super.key, required this.data, required this.isPriest});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isRejected = data.status == BookingStatus.rejected;
    
    Color statusColor = data.status == BookingStatus.approved 
        ? Colors.green 
        : (isRejected ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isPriest && isRejected) ? Colors.red.withOpacity(0.03) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPriest && isRejected) ? Colors.red.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPriest && isRejected) ? Colors.red.withOpacity(0.05) : Colors.black.withOpacity(0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: Column(
        children: [
          _buildStatusHeader(statusColor, loc),
          ListTile(
            leading: _buildDateIcon(data.date, isPriest && isRejected),
            title: Text(
              data.title, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (isPriest && isRejected) ? Colors.red.shade900 : null,
              )
            ),
            subtitle: Text(
              isPriest ? "${loc.requestedBy}: ${data.requestedBy}" : data.location,
              style: TextStyle(color: (isPriest && isRejected) ? Colors.red.withOpacity(0.7) : null),
            ),
          ),

          if (isPriest) 
            _buildPriestActionArea(context, loc) 
          else 
            _buildMemberActionArea(loc),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- MEMBER AREA (Strictly No Changes) ---
  Widget _buildMemberActionArea(AppLocalizations loc) {
    if (data.status == BookingStatus.pending) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity, 
          child: OutlinedButton(onPressed: () {}, child: Text(loc.cancelRequest))
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // --- PRIEST AREA (Workable & Transforming) ---
  Widget _buildPriestActionArea(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: data.status == BookingStatus.pending
          ? _buildInitialPriestActions(context, loc)
          : _buildTransformedPriestActions(context, loc),
    );
  }

  Widget _buildInitialPriestActions(BuildContext context, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => _updateStatus(context, loc.approved),
          child: Text(loc.approve),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
          onPressed: () => _updateStatus(context, loc.rejected),
          child: Text(loc.reject),
        )),
      ],
    );
  }

  Widget _buildTransformedPriestActions(BuildContext context, AppLocalizations loc) {
    final bool isApproved = data.status == BookingStatus.approved;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: (isApproved ? Colors.red : Colors.green).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isApproved ? Colors.red : Colors.green).withOpacity(0.1)),
      ),
      child: TextButton.icon(
        icon: Icon(isApproved ? Icons.swap_horiz : Icons.check_circle_outline, size: 18),
        label: Text(isApproved ? loc.moveToRejected : loc.moveToApproved),
        onPressed: () => _updateStatus(context, isApproved ? loc.rejected : loc.approved),
        style: TextButton.styleFrom(foregroundColor: isApproved ? Colors.red : Colors.green),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildStatusHeader(Color color, AppLocalizations loc) {
    String statusText = data.status == BookingStatus.approved ? loc.approved : (data.status == BookingStatus.pending ? loc.pending : loc.rejected);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data.id, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Text(statusText.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDateIcon(String dateStr, bool isRejected) {
    final parts = dateStr.split(' ');
    final Color iconColor = isRejected ? Colors.red : const Color(0xFF5D3A99);
    return Container(
      width: 45,
      decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parts[0], style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
          Text(parts[1].toUpperCase(), style: TextStyle(fontSize: 10, color: iconColor)),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}