import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/routes.dart';
import '../widgets/app_drawer.dart';
import 'certificate_model.dart';
import 'certificate_service.dart';
import 'certificate_request_form.dart';
import 'certificate_request_card.dart';
import '../core/models/paginated_response.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CertificateService _certificateService = CertificateService();

  List<CertificateRequest> _requests = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  // Priest Filter State
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
    _fetchRequests(isRefresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchRequests(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchRequests({
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
      final user = AuthService().currentUser;
      final bool isPriest = user?.isOfficial ?? false;
      final int pageToFetch = isLoadMore ? _currentPage + 1 : 1;
      PaginatedResponse<CertificateRequest> response;

      if (isPriest) {
        response = await _certificateService.fetchChurchRequests(
          status:
              _selectedFilter == 'All' ? null : _selectedFilter.toUpperCase(),
          page: pageToFetch,
          limit: _limit,
        );
      } else {
        response = await _certificateService.fetchMyRequests(
          page: pageToFetch,
          limit: _limit,
        );
      }

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _requests.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _requests = response.data;
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
            _fetchRequests(isLoadMore: true);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load certificate requests'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _refreshRequests() {
    _fetchRequests(isRefresh: true);
  }

  Future<void> _approveRequest(
    String id,
    Map<String, dynamic> officialDetails,
    AppLocalizations loc,
  ) async {
    try {
      final message = await _certificateService.approveRequest(
        id,
        body: officialDetails,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(
    String id,
    String? reason,
    AppLocalizations loc,
  ) async {
    try {
      final message = await _certificateService.rejectRequest(id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;

    if (user == null) {
      final navigator = Navigator.of(context);
      Future.microtask(() => navigator.pushReplacementNamed(Routes.login));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isPriest = user.isOfficial;

    if (isPriest) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: AppDrawer(user: user),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 130.0,
                pinned: true,
                floating: false,
                backgroundColor: const Color(0xFF5D3A99),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    loc.manageCertificates,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              _buildFilterBar(loc, theme),
              Expanded(child: _buildPriestHistoryTab(loc, theme, isDark)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 130.0,
              pinned: true,
              floating: false,
              backgroundColor: const Color(0xFF5D3A99),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 50),
                centerTitle: true,
                title: Text(
                  loc.certificates,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF5D3A99),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF5D3A99),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: loc.requestCertificate),
                      Tab(text: loc.myRequests),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestTab(loc, theme, isDark),
            _buildHistoryTab(loc, theme, isDark),
          ],
        ),
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
                              ? (loc.all)
                              : (f == "Pending"
                                  ? (loc.pending)
                                  : (f == "Approved"
                                      ? (loc.approved)
                                      : (loc.rejected))),
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
                        setState(() {
                          _selectedFilter = f;
                          _refreshRequests();
                        });
                      },
                      selectedColor: const Color(0xFF5D3A99),
                      backgroundColor:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPriestHistoryTab(
    AppLocalizations loc,
    ThemeData theme,
    bool isDark,
  ) {
    if (_isLoading && _requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _refreshRequests(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5D3A99).withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF5D3A99),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.noPendingCertificates,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshRequests(),
      child: ListView.builder(
        controller: _scrollController,
        key: const PageStorageKey('priest_requests_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5D3A99)),
              ),
            );
          }
          final req = _requests[index];
          return CertificateRequestCard(
            request: req,
            loc: loc,
            theme: theme,
            isDark: isDark,
            isPriest: true,
            onApprove:
                (officialDetails) =>
                    _approveRequest(req.id, officialDetails, loc),
            onReject: (reason) => _rejectRequest(req.id, reason, loc),
          );
        },
      ),
    );
  }

  Widget _buildRequestTab(AppLocalizations loc, ThemeData theme, bool isDark) {
    return CertificateRequestForm(
      onSubmitted: _refreshRequests,
      tabController: _tabController,
    );
  }

  Widget _buildHistoryTab(AppLocalizations loc, ThemeData theme, bool isDark) {
    if (_isLoading && _requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _refreshRequests(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5D3A99).withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xFF5D3A99),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.noRequestsFound,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshRequests(),
      child: ListView.builder(
        controller: _scrollController,
        key: const PageStorageKey('user_requests_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5D3A99)),
              ),
            );
          }
          return CertificateRequestCard(
            request: _requests[index],
            loc: loc,
            theme: theme,
            isDark: isDark,
            isPriest: false,
          );
        },
      ),
    );
  }
}
