import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../core/notification_helper.dart';
import 'complaint_model.dart';
import 'complaint_service.dart';

class LocalReply {
  final String? id;
  final String message;
  final String userId;
  final DateTime createdAt;
  final ComplaintUser? user;
  String status; // 'sending', 'sent', 'failed'

  LocalReply({
    this.id,
    required this.message,
    required this.userId,
    required this.createdAt,
    this.user,
    required this.status,
  });
}

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final ComplaintService _service = ComplaintService();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isInitialLoading = true;
  bool _hasError = false;
  Complaint? _complaint;
  List<LocalReply> _replies = [];
  
  bool _isPriest = false;
  String _currentUserId = '';
  bool _isSubmittingAction = false; // For close/resolve actions
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _isPriest = user?.isOfficial ?? false;
    _currentUserId = user?.id ?? '';
    _loadInitialData();

    _notificationSubscription = notificationStreamController.stream.listen((data) {
      final String? type = data['type'];
      final String? id = data['id'] ?? data['complaintId'];
      if (type == 'COMPLAINT' && id == widget.complaintId) {
        _silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final complaint = await _service.fetchComplaintDetail(
        widget.complaintId,
        isPriest: _isPriest,
      );
      if (mounted) {
        setState(() {
          _complaint = complaint;
          _replies = complaint.replies.map((r) => LocalReply(
            id: r.id,
            message: r.message,
            userId: r.userId,
            createdAt: r.createdAt,
            user: r.user,
            status: 'sent',
          )).toList();
          _isInitialLoading = false;
          _hasError = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final complaint = await _service.fetchComplaintDetail(
        widget.complaintId,
        isPriest: _isPriest,
      );
      if (mounted) {
        setState(() {
          _complaint = complaint;
          
          final List<LocalReply> backendReplies = complaint.replies.map((r) => LocalReply(
            id: r.id,
            message: r.message,
            userId: r.userId,
            createdAt: r.createdAt,
            user: r.user,
            status: 'sent',
          )).toList();
          
          final localPending = _replies.where((r) => r.status != 'sent').toList();
          _replies = [...backendReplies, ...localPending];
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Silent refresh failed: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final newLocalReply = LocalReply(
      message: text,
      userId: _currentUserId,
      createdAt: DateTime.now(),
      user: ComplaintUser(
        name: AuthService().currentUser?.name ?? '',
        role: AuthService().currentUser?.role ?? 'MEMBER',
        profilePicUrl: AuthService().currentUser?.profilePicUrl,
      ),
      status: 'sending',
    );

    setState(() {
      _replies.add(newLocalReply);
    });
    _replyController.clear();
    _scrollToBottom();

    try {
      await _service.sendReply(
        widget.complaintId,
        text,
        isPriest: _isPriest,
      );
      if (mounted) {
        setState(() {
          newLocalReply.status = 'sent';
        });
        _silentRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          newLocalReply.status = 'failed';
        });
      }
    }
  }

  Future<void> _retrySend(LocalReply localReply) async {
    setState(() {
      localReply.status = 'sending';
    });

    try {
      await _service.sendReply(
        widget.complaintId,
        localReply.message,
        isPriest: _isPriest,
      );
      if (mounted) {
        setState(() {
          localReply.status = 'sent';
        });
        _silentRefresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          localReply.status = 'failed';
        });
      }
    }
  }

  Future<void> _closeComplaint() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isSubmittingAction = true;
    });
    try {
      await _service.closeComplaint(widget.complaintId);
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorOccurred),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAction = false;
        });
      }
    }
  }

  Future<void> _resolveComplaint() async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _isSubmittingAction = true;
    });
    try {
      await _service.resolveComplaint(widget.complaintId);
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorOccurred),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.complaintDetails),
        backgroundColor: const Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || _complaint == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      loc.errorOccurred,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _isSubmittingAction
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildComplaintHeader(_complaint!, theme, isDark),
                        Expanded(
                          child: _buildChatArea(theme, isDark),
                        ),
                        if (_complaint!.status.toUpperCase() != 'CLOSED')
                          _buildInputArea(theme, isDark),
                        if (_complaint!.status.toUpperCase() == 'CLOSED')
                          Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'This complaint is closed',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildComplaintHeader(Complaint complaint, ThemeData theme, bool isDark) {
    final statusColor = _getStatusColor(complaint.status);
    final formattedDate = complaint.createdAt.toLocal().toString().substring(0, 16);
    final loc = AppLocalizations.of(context)!;
    final isClosed = complaint.status.toUpperCase() == 'CLOSED';
    final isResolved = complaint.status.toUpperCase() == 'RESOLVED';
    final showActions = (_isPriest && (complaint.status.toUpperCase() == 'OPEN' || complaint.status.toUpperCase() == 'IN_PROGRESS')) ||
                        (!_isPriest && !isClosed);

    String statusText = complaint.status;
    if (complaint.status.toUpperCase() == 'OPEN') statusText = loc.complaintStatusOpen;
    if (complaint.status.toUpperCase() == 'IN_PROGRESS') statusText = loc.complaintStatusInProgress;
    if (complaint.status.toUpperCase() == 'RESOLVED') statusText = loc.complaintStatusResolved;
    if (complaint.status.toUpperCase() == 'CLOSED') statusText = loc.complaintStatusClosed;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isPriest && complaint.user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            complaint.user!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showActions)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPriest ? Colors.green.shade700 : Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _isPriest ? _resolveComplaint : _closeComplaint,
                  icon: Icon(
                    _isPriest ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _isPriest ? loc.resolveComplaint : loc.closeComplaint,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ThemeData theme, bool isDark) {
    if (_replies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: theme.hintColor),
            const SizedBox(height: 8),
            Text(
              'No messages yet. Start the conversation!',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _replies.length,
      itemBuilder: (context, index) {
        final reply = _replies[index];
        final isSelf = reply.userId == _currentUserId;
        return _buildChatBubble(reply, isSelf, theme, isDark);
      },
    );
  }

  Widget _buildChatBubble(LocalReply reply, bool isSelf, ThemeData theme, bool isDark) {
    final formattedTime = reply.createdAt.toLocal().toString().substring(11, 16);
    final bubbleColor = isSelf
        ? const Color(0xFF5D3A99)
        : (isDark ? Colors.grey[850] : Colors.grey[200]);
    final textColor = isSelf
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final senderName = reply.user?.name ?? (isSelf ? 'You' : 'User');
    final senderRole = reply.user?.role ?? '';

    final bool isOfficialRole = User.isRoleOfficial(senderRole);
    final String displayRole = isOfficialRole ? senderRole.toUpperCase() : 'MEMBER';
    final Color badgeBgColor = isOfficialRole
        ? const Color(0xFF5D3A99).withOpacity(0.15)
        : Colors.blue.withOpacity(0.15);
    final Color badgeTextColor = isOfficialRole
        ? const Color(0xFF5D3A99)
        : Colors.blue.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor,
                ),
              ),
              if (senderRole.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayRole,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSelf)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                      ),
                      if (reply.status == 'sending') ...[
                        const SizedBox(height: 4),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D3A99)),
                          ),
                        ),
                      ],
                      if (reply.status == 'failed') ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _retrySend(reply),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 14, color: Colors.red),
                              SizedBox(width: 2),
                              Text(
                                "Failed - Tap to retry",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Flexible(
                child: GestureDetector(
                  onTap: reply.status == 'failed' ? () => _retrySend(reply) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: reply.status == 'failed' ? Colors.red.shade900.withOpacity(0.2) : bubbleColor,
                      border: reply.status == 'failed' ? Border.all(color: Colors.red.shade800, width: 1.5) : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isSelf ? 16 : 0),
                        bottomRight: Radius.circular(isSelf ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      reply.message,
                      style: TextStyle(
                        color: reply.status == 'failed' ? Colors.red.shade300 : textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    formattedTime,
                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: loc.replyHint,
                hintStyle: TextStyle(color: theme.hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF5D3A99),
            onPressed: _sendReply,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.orange.shade700;
      case 'IN_PROGRESS':
        return Colors.blue.shade700;
      case 'RESOLVED':
        return Colors.green.shade700;
      case 'CLOSED':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }
}
