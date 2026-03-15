import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'booking_model.dart';
import 'booking_service.dart';
import 'booking_card.dart'; // Import the card

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = "All";
  final BookingService _service = BookingService();
  late Future<List<BookingData>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  void _refreshBookings() {
    setState(() {
      _bookingsFuture = _service.fetchBookings();
    });
  }

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isPriest ? loc.manageRequests : loc.myBookings),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: AppDrawer(user: user),
      floatingActionButton: !isPriest
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.newBooking);
                _refreshBookings();
              },
              backgroundColor: const Color(0xFF5D3A99),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(loc.newBooking),
            )
          : null,
      body: Column(
        children: [
          _buildFilterBar(loc, theme),
          Expanded(
            child: FutureBuilder<List<BookingData>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text(loc.errorOccurred));
                }

                final allBookings = snapshot.data ?? [];
                final filteredBookings = _selectedFilter == "All"
                    ? allBookings
                    : allBookings.where((b) => b.status.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();

                return RefreshIndicator(
                  onRefresh: () async => _refreshBookings(),
                  child: filteredBookings.isEmpty
                      ? Center(child: Text(loc.noBookingsFound))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) => BookingCard(
                            data: filteredBookings[index],
                            isPriest: isPriest,
                            onRefresh: _refreshBookings,
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

  Widget _buildFilterBar(AppLocalizations loc, ThemeData theme) {
    final filters = ["All", "Pending", "Approved", "Rejected"];
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: theme.cardColor, border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: filters.map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      f == "All" ? loc.all : (f == "Pending" ? loc.pending : (f == "Approved" ? loc.approved : loc.rejected)),
                      style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedFilter = f),
                  selectedColor: const Color(0xFF5D3A99),
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  side: BorderSide(color: isSelected ? const Color(0xFF5D3A99) : Colors.transparent),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}