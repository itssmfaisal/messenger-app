import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../services/api_service.dart';
import '../services/chat_head_service.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late TextEditingController _searchController;
  String _query = '';
  bool _isChatHeadActive = false;
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
    _syncChatHeadStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesProvider = context.watch<MessagesProvider>();
    final presenceProvider = context.watch<PresenceProvider>();
    final conversations = messagesProvider.conversations;
    final filtered = conversations.where((conversation) {
      if (_query.isEmpty) return true;
      final username = conversation.partner.toLowerCase();
      final displayName =
          messagesProvider.getDisplayName(conversation.partner).toLowerCase();
      return username.contains(_query) || displayName.contains(_query);
    }).toList();

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleChatHead,
                        icon: Icon(
                          _isChatHeadActive
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                        ),
                        color: _isChatHeadActive
                            ? const Color(0xFF35BE86)
                            : const Color(0xFF98A2B3),
                        tooltip: _isChatHeadActive
                            ? 'Disable chat bubble'
                            : 'Enable chat bubble',
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined),
                        color: const Color(0xFF98A2B3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _searchBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        icon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9AA3B2),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Color(0xFF9AA3B2),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (conversations.isNotEmpty)
                    _buildChatHeadsStrip(conversations, presenceProvider),
                  if (conversations.isNotEmpty) const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last chats',
                          style: TextStyle(
                            color: Color(0xFF697386),
                            fontSize: 16,
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
            child: Builder(
              builder: (context) {
                if (messagesProvider.isLoading && conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
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

  Future<void> _syncChatHeadStatus() async {
    final active = await ChatHeadService.isChatHeadRunning();
    if (!mounted) return;
    setState(() => _isChatHeadActive = active);
  }

  Future<void> _toggleChatHead() async {
    if (_isChatHeadActive) {
      await ChatHeadService.stopChatHead();
      if (!mounted) return;
      setState(() => _isChatHeadActive = false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Long-press any conversation to open chat head.'),
      ),
    );
  }

  Future<void> _startChatHeadForPartner(String partner) async {
    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    final granted = await ChatHeadService.ensureOverlayPermission();
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allow display over other apps to use chat bubble.'),
        ),
      );
      return;
    }

    if (messagesProvider.conversations.isEmpty || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open at least one conversation first.')),
      );
      return;
    }

    await ChatHeadService.startChatHead(
      label: partner,
      partner: partner,
      token: authProvider.token!,
      currentUsername: authProvider.currentUsername ?? '',
    );
    if (!mounted) return;
    setState(() => _isChatHeadActive = true);
  }

  Widget _buildChatHeadsStrip(
    List<Conversation> conversations,
    PresenceProvider presenceProvider,
  ) {
    final heads = conversations.take(10).toList();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: heads.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final conversation = heads[index];
            final displayName =
              context.read<MessagesProvider>().getDisplayName(conversation.partner);
          final isOnline =
              presenceProvider.presenceStatus[conversation.partner] ?? false;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatDetailScreen(partner: conversation.partner),
                ),
              );
            },
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: _getPartnerAvatarUrl(conversation.partner),
                    builder: (context, snapshot) {
                      final imageUrl = snapshot.data;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: const Color(0xFFD7DEE9),
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl == null
                                ? Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF556071),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _pageBg, width: 2),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6F7888),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getPartnerAvatarUrl(String username) {
    return _avatarFutures.putIfAbsent(username, () async {
      try {
        final profile = await context.read<ApiService>().getUserProfile(
          username,
        );
        final path = profile.profilePictureUrl;
        if (path == null || path.isEmpty) return null;
        return resolveApiUrl(path);
      } catch (_) {
        return null;
      }
    });
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
  ) {
    final displayName =
        context.read<MessagesProvider>().getDisplayName(conversation.partner);

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
      onLongPress: () => _showConversationActions(conversation),
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
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Text(
                          displayName[0].toUpperCase(),
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
                displayName,
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
                    presenceProvider.presenceStatus[conversation.partner] ??
                    false;
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

  void _showConversationActions(Conversation conversation) {
    final displayName =
        context.read<MessagesProvider>().getDisplayName(conversation.partner);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DDE6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_rounded),
                title: Text('Open $displayName as chat head'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _startChatHeadForPartner(conversation.partner);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
