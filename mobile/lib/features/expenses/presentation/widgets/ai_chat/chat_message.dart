import '../../../domain/entities/expense.dart';

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
