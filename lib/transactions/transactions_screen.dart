import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/routes.dart';
import 'transaction_model.dart';
import 'transaction_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _service = TransactionService();
  final ScrollController _scrollController = ScrollController();

  List<Transaction> _transactions = [];
  double _totalAmount = 0.0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  bool _hasMore = false;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchTransactions(isRefresh: true);
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
        _fetchTransactions(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchTransactions({
    bool isRefresh = false,
    bool isLoadMore = false,
  }) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _hasMore = false;
        _hasError = false;
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
        _hasError = false;
      });
    }

    try {
      final int pageToFetch = isLoadMore ? _currentPage + 1 : 1;

      // Only fetch the total amount on the first page / refresh
      if (pageToFetch == 1) {
        final total = await _service.fetchTotalAmount();
        if (mounted) {
          setState(() {
            _totalAmount = total;
          });
        }
      }

      final response = await _service.fetchTransactions(
        page: pageToFetch,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _transactions.addAll(response.data);
            _currentPage = pageToFetch;
          } else {
            _transactions = response.data;
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
            _fetchTransactions(isLoadMore: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (_transactions.isEmpty) {
            _hasError = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load transactions'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _refreshTransactions() {
    _fetchTransactions(isRefresh: true);
  }

  Future<void> _downloadReport() async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT MONTH FOR REPORT',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && mounted) {
      String month = DateFormat('yyyy-MM').format(picked);
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.downloadReport} $month...')),
      );

      String message = await _service.downloadReport(month);

      if (mounted) {
        final bool isSuccess = message.contains("successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                isSuccess
                    ? Colors.green
                    : (message.contains("Failed") ? Colors.red : Colors.orange),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          loc.transactions,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF5D3A99),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: "Download Monthly Report",
            onPressed: _downloadReport,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addTransaction).then((_) {
            _refreshTransactions();
          });
        },
        backgroundColor: const Color(0xFF5D3A99),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          loc.newTransaction,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5D3A99)),
            )
          : _hasError && _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load transactions",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => _refreshTransactions(),
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: Color(0xFF5D3A99)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF5D3A99),
                  onRefresh: () async => _refreshTransactions(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildTotalCard(_totalAmount, loc),
                      ),
                      if (_transactions.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              loc.noTransactionsFound,
                              style: TextStyle(color: mutedTextColor, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              if (index == _transactions.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF5D3A99),
                                    ),
                                  ),
                                );
                              }
                              final tx = _transactions[index];
                              return _buildTransactionCard(
                                tx,
                                isDark,
                                cardBg,
                                textColor,
                                mutedTextColor,
                                loc,
                              );
                            }, childCount: _transactions.length + (_isLoadingMore ? 1 : 0)),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ), // FAB padding
                    ],
                  ),
                ),
    );
  }

  Widget _buildTotalCard(double totalAmount, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D3A99), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D3A99).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            loc.totalBalance,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${NumberFormat('#,##0.00').format(totalAmount)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction tx,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color? mutedTextColor,
    AppLocalizations loc,
  ) {
    final bool isIncome = tx.type == TransactionType.INCOME;
    final Color typeColor = isIncome ? Colors.green : Colors.red;
    final String sign = isIncome ? "+" : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TransactionCategories.formatCategory(tx.category),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        tx.paymentMethod == PaymentMethod.CASH
                            ? Icons.money
                            : Icons.account_balance,
                        size: 14,
                        color: mutedTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tx.paymentMethod.name,
                        style: TextStyle(color: mutedTextColor, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('MMM dd, yyyy').format(tx.date),
                        style: TextStyle(color: mutedTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                  if (tx.remarks != null && tx.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tx.remarks!,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${loc.addedBy}: ${tx.createdBy.name} (${tx.createdBy.role})",
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$sign ₹${NumberFormat('#,##0').format(tx.amount)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: typeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
