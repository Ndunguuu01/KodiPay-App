import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../utils/constants.dart';
import 'compose_message_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<MessageProvider>(context, listen: false).fetchMessages());
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

          // Group messages by conversation
          final Map<String, dynamic> conversations = {};
          final currentUserId = Provider.of<AuthProvider>(context, listen: false).userId;
          
          for (var message in provider.messages) {
            String key;
            String title;
            int? targetUserId;
            int? groupId;
            
            if (message.groupId != null) {
              key = 'group_${message.groupId}';
              title = 'Property Group ${message.groupId}'; // Ideally fetch property name
              groupId = message.groupId;
            } else {
              final otherId = message.senderId == currentUserId 
                  ? message.receiverId 
                  : message.senderId;
              key = 'user_$otherId';
              
              // Determine Title (Name of the other person)
              if (message.senderId == currentUserId) {
                // I sent it, show Receiver Name
                title = message.receiverName ?? 'User $otherId';
              } else {
                // I received it, show Sender Name
                title = message.senderName ?? 'User $otherId';
              }
              targetUserId = otherId;
            }

            // Keep the latest message for the preview
            if (!conversations.containsKey(key) || 
                (message.createdAt != null && conversations[key]['message'].createdAt!.isBefore(message.createdAt!))) {
              conversations[key] = {
                'message': message,
                'title': title,
                'targetUserId': targetUserId,
                'groupId': groupId,
              };
            }
          }

          final sortedConversations = conversations.values.toList()
            ..sort((a, b) => b['message'].createdAt!.compareTo(a['message'].createdAt!));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedConversations.length,
            itemBuilder: (context, index) {
              final conversation = sortedConversations[index];
              final message = conversation['message'];
              final title = conversation['title'];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    child: Icon(
                      conversation['groupId'] != null ? Icons.group : Icons.person,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    message.type == 'image' ? '📷 Image' : message.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: message.senderId == currentUserId ? Colors.grey : Colors.black87,
                      fontStyle: message.senderId == currentUserId ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  trailing: message.createdAt != null
                      ? Text(
                          '${message.createdAt!.hour}:${message.createdAt!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          targetUserId: conversation['targetUserId'],
                          targetUserName: title,
                          groupId: conversation['groupId'],
                          groupName: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
