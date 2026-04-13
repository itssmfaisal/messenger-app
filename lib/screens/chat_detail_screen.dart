import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../services/api_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String partner;

  const ChatDetailScreen({super.key, required this.partner});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late Future<String?> _partnerAvatarFuture;

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _titleText = Color(0xFF1E2738);
  static const Color _mutedText = Color(0xFF9AA3B2);
  static const Color _incomingBubble = Color(0xFFEFF1F5);
  static const Color _outgoingBubble = Color(0xFFE8E3FF);
  static const Color _activeGreen = Color(0xFF4ED0AF);

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _partnerAvatarFuture = _getPartnerAvatarUrl();

    // Load conversation
    Future.microtask(() {
      if (!mounted) return;
      context.read<MessagesProvider>().loadConversation(widget.partner);
    });
  }

  Future<String?> _getPartnerAvatarUrl() async {
    try {
      final profile = await context.read<ApiService>().getUserProfile(widget.partner);
      final path = profile.profilePictureUrl;
      if (path == null || path.isEmpty) return null;
      return resolveApiUrl(path);
    } catch (_) {
      return null;
    }
  }

  bool _isImageAttachment(Message message) {
    final type = message.attachmentType?.toLowerCase();
    if (type != null && type.startsWith('image/')) {
      return true;
    }

    final source = (message.attachmentName ?? message.attachmentUrl ?? '').toLowerCase();
    return source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.png') ||
        source.endsWith('.gif') ||
        source.endsWith('.webp');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesProvider = context.watch<MessagesProvider>();
    final partnerDisplayName = messagesProvider.getDisplayName(widget.partner);
    final presenceProvider = context.watch<PresenceProvider>();
    final isOnline = presenceProvider.presenceStatus[widget.partner] ?? false;

    return Scaffold(
      backgroundColor: _pageBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: const Color(0xFF6D7688),
                  ),
                  FutureBuilder<String?>(
                    future: _partnerAvatarFuture,
                    builder: (context, snapshot) {
                      final imageUrl = snapshot.data;
                      return CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFD4DCE8),
                        backgroundImage:
                            imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null
                            ? Text(
                            partnerDisplayName.isNotEmpty
                              ? partnerDisplayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF5A6679),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerDisplayName,
                        style: const TextStyle(
                          color: _titleText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: _mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _activeGreen,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Media',
                  style: TextStyle(
                    color: _mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, messagesProvider, _) {
                final messages = messagesProvider.getConversationMessages(widget.partner);

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final message = reversedMessages[index];
                    return _buildMessageBubble(context, message);
                  },
                );
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
              bottom: 8,
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Write your message...',
                        hintStyle: TextStyle(color: _mutedText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    color: const Color(0xFF8E97A7),
                    onPressed: () {},
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF90E3CD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    context.read<MessagesProvider>().sendMessage(widget.partner, content).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  Widget _buildMessageBubble(BuildContext context, Message message) {
    final isFromMe = message.sender == context.read<AuthProvider>().currentUsername;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          crossAxisAlignment:
              isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFromMe
                        ? 'You'
                        : context.read<MessagesProvider>().getDisplayName(message.sender),
                    style: const TextStyle(
                      color: Color(0xFF697386),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat.Hm().format(message.sentAt),
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe ? _outgoingBubble : _incomingBubble,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentUrl != null && _isImageAttachment(message))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          resolveApiUrl(message.attachmentUrl!),
                          width: 170,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 170,
                            height: 140,
                            color: const Color(0xFFDDE3EC),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined,
                                color: Color(0xFF6B7689)),
                          ),
                        ),
                      ),
                    ),
                  if (message.attachmentUrl != null && !_isImageAttachment(message))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFC9D0DD),
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: const Color(0xFF4B5567),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message.attachmentName ?? 'File',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5567),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFF3D4656),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isFromMe)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 4),
                child: Icon(
                  message.status == 'SEEN' ? Icons.done_all : Icons.done_all,
                  size: 15,
                  color: message.status == 'SEEN'
                      ? const Color(0xFF53C6E2)
                      : const Color(0xFFC4C9D5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
