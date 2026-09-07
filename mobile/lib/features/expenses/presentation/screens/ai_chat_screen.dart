import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/category_icon.dart';

// ─── Chat Message Model ─────────────────────────────────────────────────────

enum ChatMessageType { user, ai, system }
enum ChatMessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final ChatMessageStatus status;
  final DateTime timestamp;
  final ExpenseEntity? savedExpense;
  final bool saved;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.status = ChatMessageStatus.sent,
    DateTime? timestamp,
    this.savedExpense,
    this.saved = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    ChatMessageStatus? status,
    ExpenseEntity? savedExpense,
    bool? saved,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      savedExpense: savedExpense ?? this.savedExpense,
      saved: saved ?? this.saved,
    );
  }
}

// ─── AI Chat Screen ─────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final DioClient _client = DioClient();

  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _messageIdCounter = 0;

  // Typing indicator animation
  late AnimationController _typingController;
  late Animation<double> _typingDot1;
  late Animation<double> _typingDot2;
  late Animation<double> _typingDot3;

  @override
  void initState() {
    super.initState();

    // Typing dots animation
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _typingDot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );
    _typingDot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );
    _typingDot3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Welcome message
    _addSystemMessage(
      '👋 Hai! Saya asisten AI untuk mencatat pengeluaran.\n\n'
      'Cukup ketik pesan seperti:\n'
      '• "makan siang 25k"\n'
      '• "kopi starbucks 45000"\n'
      '• "bensin 50k"\n'
      '• "kemarin belanja indomaret 120k"\n\n'
      'Saya akan otomatis memahami dan menyimpan transaksi kamu! 🚀',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingController.dispose();
    super.dispose();
  }

  String _generateId() {
    _messageIdCounter++;
    return 'msg_$_messageIdCounter';
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        id: _generateId(),
        text: text,
        type: ChatMessageType.system,
      ));
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isAiTyping) return;

    _messageController.clear();

    // Add user message
    final userMsgId = _generateId();
    setState(() {
      _messages.add(ChatMessage(
        id: userMsgId,
        text: text,
        type: ChatMessageType.user,
        status: ChatMessageStatus.sent,
      ));
      _isAiTyping = true;
    });
    _scrollToBottom();

    try {
      // Get current wallet
      final dashboardState = context.read<DashboardBloc>().state;
      final walletId = dashboardState.activeWallet?.id;

      // Call API
      final payload = <String, dynamic>{
        'message': text,
        'timezone': 'Asia/Jakarta',
      };
      if (walletId != null) {
        payload['walletId'] = walletId;
      }

      final response = await _client.dio.post(
        '/chat/transaction',
        data: payload,
      );

      if (!mounted) return;

      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        final aiMessage = data['aiMessage'] ?? 'Transaksi diproses.';
        final saved = data['saved'] == true;

        ExpenseEntity? savedExpense;
        if (saved && data['expense'] != null) {
          try {
            savedExpense = ExpenseEntity.fromJson(data['expense']);
          } catch (_) {
            // Silently ignore parse errors
          }
        }

        setState(() {
          _isAiTyping = false;
          _messages.add(ChatMessage(
            id: _generateId(),
            text: aiMessage,
            type: ChatMessageType.ai,
            status: ChatMessageStatus.sent,
            savedExpense: savedExpense,
            saved: saved,
          ));
        });

        // Refresh dashboard if saved
        if (saved && mounted) {
          context.read<DashboardBloc>().add(const DashboardRefreshRequested());
        }
      } else {
        final errorMsg = responseData['message'] ?? 'Gagal memproses pesan';
        setState(() {
          _isAiTyping = false;
          _messages.add(ChatMessage(
            id: _generateId(),
            text: errorMsg,
            type: ChatMessageType.ai,
            status: ChatMessageStatus.sent,
          ));
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMessage = _client.getErrorMessage(e);
      setState(() {
        _isAiTyping = false;
        _messages.add(ChatMessage(
          id: _generateId(),
          text: '❌ $errorMessage',
          type: ChatMessageType.ai,
          status: ChatMessageStatus.error,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        _messages.add(ChatMessage(
          id: _generateId(),
          text: '❌ Terjadi kesalahan. Silakan coba lagi.',
          type: ChatMessageType.ai,
          status: ChatMessageStatus.error,
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final dashboardState = context.watch<DashboardBloc>().state;
    final currencyCode = dashboardState.activeWallet?.currency ?? 'IDR';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(responsive),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(responsive)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scale(16),
                      vertical: 16,
                    ),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isAiTyping) {
                        return _buildTypingIndicator(responsive);
                      }
                      return _buildMessageBubble(
                        _messages[index],
                        responsive,
                        currencyCode,
                      );
                    },
                  ),
          ),

          // Quick suggestion chips
          if (_messages.length <= 2) _buildSuggestionChips(responsive),

          // Input field
          _buildInputArea(responsive),
        ],
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ResponsiveHelper responsive) {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onBackground),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.scaleFont(16),
                  color: AppTheme.onBackground,
                ),
              ),
              Text(
                _isAiTyping ? 'Mengetik...' : 'Online',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: _isAiTyping ? AppTheme.tertiary : AppTheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(ResponsiveHelper responsive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Expense Assistant',
              style: AppTheme.headlineSm.copyWith(
                color: AppTheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketik pesan untuk menyimpan transaksi',
              style: AppTheme.bodyMd.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Message Bubbles ──────────────────────────────────────────────────────

  Widget _buildMessageBubble(
    ChatMessage message,
    ResponsiveHelper responsive,
    String currencyCode,
  ) {
    switch (message.type) {
      case ChatMessageType.user:
        return _buildUserBubble(message, responsive);
      case ChatMessageType.ai:
        return _buildAiBubble(message, responsive, currencyCode);
      case ChatMessageType.system:
        return _buildSystemBubble(message, responsive);
    }
  }

  Widget _buildUserBubble(ChatMessage message, ResponsiveHelper responsive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(
    ChatMessage message,
    ResponsiveHelper responsive,
    String currencyCode,
  ) {
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);
    final hasSaved = message.saved && message.savedExpense != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withAlpha(128),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.beVietnamPro(
                      color: AppTheme.onBackground,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

                // Saved expense card
                if (hasSaved) ...[
                  const SizedBox(height: 8),
                  _buildSavedExpenseCard(message.savedExpense!, currencyFormatter),
                ],
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(ChatMessage message, ResponsiveHelper responsive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withAlpha(25),
              width: 1,
            ),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ─── Saved Expense Card ───────────────────────────────────────────────────

  Widget _buildSavedExpenseCard(
    ExpenseEntity expense,
    NumberFormat currencyFormatter,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondary.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.parseHexColor(expense.category.color).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CategoryIcon(
                icon: expense.category.icon,
                color: AppTheme.parseHexColor(expense.category.color),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description ?? 'Expense',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${currencyFormatter.format(expense.amount)} · ${expense.category.name}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.secondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Typing Indicator ─────────────────────────────────────────────────────

  Widget _buildTypingIndicator(ResponsiveHelper responsive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: AppTheme.outlineVariant.withAlpha(128),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(_typingDot1),
                    const SizedBox(width: 4),
                    _buildDot(_typingDot2),
                    const SizedBox(width: 4),
                    _buildDot(_typingDot3),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return Transform.translate(
      offset: Offset(0, -4 * animation.value),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha((100 + 155 * animation.value).toInt()),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─── Suggestion Chips ─────────────────────────────────────────────────────

  Widget _buildSuggestionChips(ResponsiveHelper responsive) {
    final suggestions = [
      '☕ Kopi 15k',
      '🍔 Makan siang 25k',
      '⛽ Bensin 50k',
      '🛒 Belanja 120k',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Remove the emoji prefix for the actual message
                    final cleanText = suggestion.replaceFirst(RegExp(r'^[^\w]+\s*'), '');
                    _messageController.text = cleanText;
                    _sendMessage();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Input Area ───────────────────────────────────────────────────────────

  Widget _buildInputArea(ResponsiveHelper responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withAlpha(128),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 1,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            color: AppTheme.onBackground,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tulis pengeluaran... (cth: makan siang 25k)',
                            hintStyle: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: AppTheme.outline,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: false,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                child: Material(
                  color: _isAiTyping
                      ? AppTheme.outline.withAlpha(51)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isAiTyping ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: _isAiTyping
                            ? AppTheme.outline
                            : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
