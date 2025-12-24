import 'package:dartz/dartz.dart';
import 'package:medical_app/features/messagerie/data/models/message_model.dart';
import 'package:medical_app/features/messagerie/data/models/conversation_model.dart';

abstract class MessagingLocalDataSource {
  Future<Unit> cacheConversations(List<ConversationModel> conversations);
  Future<List<ConversationModel>> getCachedConversations();
  Future<Unit> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  );
  Future<List<MessageModel>> getCachedMessages(String conversationId);
}

class MessagingLocalDataSourceImpl implements MessagingLocalDataSource {
  MessagingLocalDataSourceImpl();

  @override
  Future<Unit> cacheConversations(List<ConversationModel> conversations) async {
    throw UnimplementedError('Caching not implemented');
  }

  @override
  Future<List<ConversationModel>> getCachedConversations() async {
    throw UnimplementedError('Caching not implemented');
  }

  @override
  Future<Unit> cacheMessages(
    String conversationId,
    List<MessageModel> messages,
  ) async {
    throw UnimplementedError('Caching not implemented');
  }

  @override
  Future<List<MessageModel>> getCachedMessages(String conversationId) async {
    throw UnimplementedError('Caching not implemented');
  }
}
