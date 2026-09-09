import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/ai_chat/ai_chat.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final DioClient _client = DioClient();

  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  int _messageIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _addSystemMessage(
      '👋 Hai! Saya asisten AI untuk mencatat pengeluaran.\n\n'
      'Cukup ketik pesan seperti:\n'
      '• "makan siang 25k"\n'
      '• "kopi 15k jam 10 pagi"\n'
      '• "bensin 50rb jam 14.30"\n'
      '• "kemarin martabak 35k jam 8 malam"\n\n'
      '💡 Jika tidak menyertakan jam, otomatis dicatat pada jam sekarang!\n'
      'Saya akan otomatis memahami dan menyimpan transaksi kamu! 🚀',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
      final dashboardState = context.read<DashboardBloc>().state;
      final walletId = dashboardState.activeWallet?.id;

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
    } catch (_) {
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

  PreferredSizeWidget _buildAppBar(ResponsiveHelper responsive) {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppTheme.onBackground),
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
          Expanded(
            child: _messages.isEmpty
                ? AiChatEmptyState(responsive: responsive)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scale(16),
                      vertical: 16,
                    ),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isAiTyping) {
                        return AiChatTypingIndicator(responsive: responsive);
                      }
                      return AiChatBubble(
                        message: _messages[index],
                        responsive: responsive,
                        currencyCode: currencyCode,
                      );
                    },
                  ),
          ),
          if (_messages.length <= 2)
            AiChatSuggestionChips(
              onSelectSuggestion: (text) {
                _messageController.text = text;
                _sendMessage();
              },
            ),
          AiChatInputBar(
            controller: _messageController,
            focusNode: _focusNode,
            isAiTyping: _isAiTyping,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
