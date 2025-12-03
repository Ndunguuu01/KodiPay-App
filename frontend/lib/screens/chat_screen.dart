import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../utils/constants.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final int? targetUserId;
  final String? targetUserName;
  final int? groupId;
  final String? groupName;

  const ChatScreen({
    super.key,
    this.targetUserId,
    this.targetUserName,
    this.groupId,
    this.groupName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch messages when screen opens
    Future.microtask(() =>
        Provider.of<MessageProvider>(context, listen: false).fetchMessages());
  }

  void _sendMessage(String text, XFile? image) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<MessageProvider>(context, listen: false);

    String? content = text;
    String type = 'text';

    if (image != null) {
      final bytes = await image.readAsBytes();
      content = base64Encode(bytes);
      type = 'image';
    }

    final message = Message(
      senderId: auth.userId!,
      receiverId: widget.targetUserId,
      groupId: widget.groupId,
      content: content,
      type: type,
    );

    await provider.sendMessage(message);
    _scrollToBottom();
  }

  void _handleTyping(String text) {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    String room = '';
    if (widget.groupId != null) {
      room = 'group_${widget.groupId}';
    } else if (widget.targetUserId != null) {
      room = 'user_${widget.targetUserId}'; // Note: This might need adjustment for 1-on-1 rooms
    }

    if (room.isNotEmpty) {
      if (text.isNotEmpty) {
        provider.sendTyping(room, auth.userName ?? 'User');
      } else {
        provider.sendStopTyping(room, auth.userName ?? 'User');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.userId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(
                widget.groupId != null ? Icons.group : Icons.person,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName ?? widget.targetUserName ?? 'Chat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Consumer<MessageProvider>(
                  builder: (context, provider, _) {
                    if (provider.isTyping && provider.typingUser != null) {
                      // Simple check: if someone is typing in the room we are looking at?
                      // The provider's isTyping is global for the socket event. 
                      // Ideally we filter by room, but for now this works as a basic indicator.
                      return const Text(
                        'typing...',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/chat_bg.png"), // Optional: Add a background pattern
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          color: Color(0xFFE5DDD5), // WhatsApp default background color
        ),
        child: Column(
          children: [
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, provider, child) {
                  // Filter messages for this chat
                  final messages = provider.messages.where((m) {
                    if (widget.groupId != null) {
                      return m.groupId == widget.groupId;
                    } else {
                      return (m.senderId == currentUserId && m.receiverId == widget.targetUserId) ||
                             (m.senderId == widget.targetUserId && m.receiverId == currentUserId);
                    }
                  }).toList();

                  if (provider.isLoading && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  // Scroll to bottom on new message
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;

                      return ChatBubble(
                        content: message.content,
                        type: message.type ?? 'text',
                        isMe: isMe,
                        timestamp: message.createdAt,
                        isRead: true, // Placeholder for read status
                      );
                    },
                  );
                },
              ),
            ),
            ChatInput(
              onSendMessage: _sendMessage,
              onTyping: _handleTyping,
            ),
          ],
        ),
      ),
    );
  }
}
