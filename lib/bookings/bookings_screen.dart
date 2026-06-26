import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'booking_model.dart';
import 'booking_service.dart';
import 'booking_card.dart'; // Import the card
import '../core/models/paginated_response.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = "All";
  final BookingService _service = BookingService();

  List<BookingData> _bookings = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchBookings(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchBookings(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchBookings({
    bool isRefresh = false,
    bool isLoadMore = false,
  }) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    } else if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
      });
    }

    try {
      final int pageToFetch = isLoadMore ? _currentPage + 1 : 1;
      final response = await _service.fetchBookings(
        page: pageToFetch,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _bookings.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _bookings = response.data;
            _currentPage = 1;
          }
          _hasMore = response.meta.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent <= 0 &&
              _hasMore &&
              !_isLoading &&
              !_isLoadingMore) {
            _fetchBookings(isLoadMore: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load bookings'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _refreshBookings() {
    _fetchBookings(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, Routes.login),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isPriest = user.isOfficial;
    final theme = Theme.of(context);

    final filteredBookings =
        _selectedFilter == "All"
            ? _bookings
            : _bookings
                .where(
                  (b) =>
                      b.status.name.toLowerCase() ==
                      _selectedFilter.toLowerCase(),
                )
                .toList();

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
      floatingActionButton:
          !isPriest
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
            child:
                _isLoading && _bookings.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5D3A99),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async => _refreshBookings(),
                      child:
                          filteredBookings.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Center(
                                      child: Text(loc.noBookingsFound),
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                itemCount:
                                    filteredBookings.length +
                                    (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == filteredBookings.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF5D3A99),
                                        ),
                                      ),
                                    );
                                  }
                                  return BookingCard(
                                    data: filteredBookings[index],
                                    isPriest: isPriest,
                                    onRefresh: _refreshBookings,
                                  );
                                },
                              ),
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
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:
                filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          f == "All"
                              ? loc.all
                              : (f == "Pending"
                                  ? loc.pending
                                  : (f == "Approved"
                                      ? loc.approved
                                      : loc.rejected)),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedFilter = f);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              _scrollController.hasClients &&
                              _scrollController.position.maxScrollExtent <= 0 &&
                              _hasMore &&
                              !_isLoading &&
                              !_isLoadingMore) {
                            _fetchBookings(isLoadMore: true);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF5D3A99),
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? const Color(0xFF5D3A99)
                                : Colors.transparent,
                      ),
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
