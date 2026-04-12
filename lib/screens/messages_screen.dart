import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, messagesProvider, _) {
                if (messagesProvider.isLoading && messagesProvider.conversations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (messagesProvider.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: messagesProvider.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = messagesProvider.conversations[index];
                    return _buildConversationTile(context, conversation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          conversation.partner[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(conversation.partner),
      subtitle: Text(
        'Last message at ${DateFormat.jm().format(conversation.lastMessageAt)}',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Consumer<PresenceProvider>(
        builder: (context, presenceProvider, _) {
          final isOnline = presenceProvider.presenceStatus[conversation.partner] ?? false;
          return isOnline
              ? Chip(
                  label: const Text('Online'),
                  backgroundColor: Colors.green.shade100,
                )
              : const SizedBox.shrink();
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatDetailScreen(partner: conversation.partner),
          ),
        );
      },
    );
  }
}
