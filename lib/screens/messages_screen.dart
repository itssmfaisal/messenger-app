import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../services/api_service.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late TextEditingController _searchController;
  String _query = '';
  final Map<String, Future<String?>> _avatarFutures = {};

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _mutedText = Color(0xFF8C96A5);
  static const Color _titleText = Color(0xFF1D2433);
  static const Color _accent = Color(0xFF4ED0AF);
  static const Color _searchBg = Color(0xFFEDEFF3);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final currentName = profileProvider.profile?.displayName?.trim().isNotEmpty == true
        ? profileProvider.profile!.displayName!
        : (authProvider.currentUsername ?? 'User');

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFF6E7788),
                      ),
                      const Expanded(
                        child: Text(
                          'Chat',
                          style: TextStyle(
                            color: _titleText,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined),
                        color: const Color(0xFF98A2B3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFCBD5E1),
                    child: Text(
                      currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentName,
                    style: const TextStyle(
                      color: _titleText,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8F5EA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: _accent),
                        SizedBox(width: 8),
                        Text(
                          'available',
                          style: TextStyle(
                            color: Color(0xFF2BA88A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF2BA88A), size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _searchBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Color(0xFF9AA3B2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last chats',
                          style: TextStyle(
                            color: Color(0xFF697386),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.add, color: Color(0xFF8E98AA)),
                      SizedBox(width: 14),
                      Icon(Icons.more_horiz, color: Color(0xFF8E98AA)),
                    ],
                  ),
                ],
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

                final filtered = messagesProvider.conversations.where((conversation) {
                  if (_query.isEmpty) return true;
                  return conversation.partner.toLowerCase().contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No chats found',
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 26),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
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

  Future<String?> _getPartnerAvatarUrl(String username) {
    return _avatarFutures.putIfAbsent(username, () async {
      try {
        final profile = await context.read<ApiService>().getUserProfile(username);
        final path = profile.profilePictureUrl;
        if (path == null || path.isEmpty) return null;
        return resolveApiUrl(path);
      } catch (_) {
        return null;
      }
    });
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatDetailScreen(partner: conversation.partner),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            FutureBuilder<String?>(
              future: _getPartnerAvatarUrl(conversation.partner),
              builder: (context, snapshot) {
                final imageUrl = snapshot.data;
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFD7DEE9),
                  backgroundImage:
                      imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Text(
                          conversation.partner[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF556071),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                conversation.partner,
                style: const TextStyle(
                  color: _titleText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Consumer<PresenceProvider>(
              builder: (context, presenceProvider, _) {
                final isOnline =
                    presenceProvider.presenceStatus[conversation.partner] ?? false;
                return Row(
                  children: [
                    if (isOnline)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.circle, size: 8, color: _accent),
                      ),
                    Text(
                      DateFormat.Hm().format(conversation.lastMessageAt),
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
