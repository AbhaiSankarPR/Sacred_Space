import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../widgets/app_drawer.dart';
import 'signup_request_model.dart';
import 'signup_request_service.dart';

class SignupRequestsScreen extends StatefulWidget {
  const SignupRequestsScreen({super.key});

  @override
  State<SignupRequestsScreen> createState() => _SignupRequestsScreenState();
}

class _SignupRequestsScreenState extends State<SignupRequestsScreen> {
  final SignupRequestService _service = SignupRequestService();
  final ScrollController _scrollController = ScrollController();

  List<SignupRequest> _pendingUsers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchPendingUsers(isRefresh: true);
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
        _fetchPendingUsers(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchPendingUsers({
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
      final response = await _service.getPendingSignups(
        page: pageToFetch,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _pendingUsers.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _pendingUsers = response.data;
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
            _fetchPendingUsers(isLoadMore: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showSnackBar(AppLocalizations.of(context)!.errorOccurred, isError: true);
      }
    }
  }

  void _refreshPendingUsers() {
    _fetchPendingUsers(isRefresh: true);
  }

  Future<void> _handleRequest(String userId, String action) async {
    try {
      await _service.handleSignupRequest(userId, action);
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.signupRequestHandled);
        _refreshPendingUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.errorOccurred, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = AuthService().currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: AppDrawer(user: user!),
      appBar: AppBar(
        title: Text(loc.signupRequests, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading && _pendingUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshPendingUsers(),
              child: _pendingUsers.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_disabled_outlined, size: 64, color: theme.hintColor),
                              const SizedBox(height: 16),
                              Text(loc.noSignupRequests, style: TextStyle(color: theme.hintColor)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: _pendingUsers.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _pendingUsers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF5D3A99)),
                            ),
                          );
                        }
                        final pendingUser = _pendingUsers[index];
                        final name = pendingUser.name;
                        final email = pendingUser.email;
                        final houseName = pendingUser.houseName;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xFF5D3A99).withOpacity(0.1),
                              child: const Icon(Icons.person_add, color: Color(0xFF5D3A99), size: 28),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email, style: TextStyle(color: theme.hintColor, fontSize: 13)),
                                Text(houseName, style: const TextStyle(color: Color(0xFF8E44AD), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Decline Button
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () => _handleRequest(pendingUser.id, 'reject'),
                                  tooltip: loc.decline,
                                ),
                                const SizedBox(width: 4),
                                // Accept Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _handleRequest(pendingUser.id, 'approve'),
                                  child: Text(loc.accept, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
