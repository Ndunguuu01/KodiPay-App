import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../utils/constants.dart';
import 'compose_message_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    Future.microtask(() =>
        Provider.of<MessageProvider>(context, listen: false).fetchMessages());
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const MessageListSkeleton(itemCount: 6);
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.messages.isEmpty) {
            return EmptyStateWidget(
              title: 'No Messages',
              message: 'You have no messages yet. Start a conversation!',
              icon: Icons.chat_bubble_outline,
              actionLabel: 'Compose Message',
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComposeMessageScreen()),
                );
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      final isMe = message.senderId == _currentUserId;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isMe ? Colors.blue[50] : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isMe ? AppConstants.primaryColor : Colors.grey,
                                  child: Icon(
                                    isMe ? Icons.person : Icons.person_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  isMe ? 'Me' : 'User ${message.senderId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: message.type == 'image'
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            base64Decode(message.content),
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Text('Error loading image');
                                            },
                                          ),
                                        ),
                                      )
                                    : Text(message.content),
                                trailing: message.createdAt != null
                                    ? Text(
                                        '${message.createdAt!.hour}:${message.createdAt!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (provider.isTyping && provider.typingUser != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.typingUser} is typing...',
                        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ComposeMessageScreen()),
          );
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
