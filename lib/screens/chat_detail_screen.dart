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
  bool _showJumpToRecent = false;
  int _lastMessageCount = 0;
  bool _hasTypedText = false;

  static const Color _pageBg = Color(0xFFF5F6F8);
  static const Color _titleText = Color(0xFF1E2738);
  static const Color _mutedText = Color(0xFF9AA3B2);
  static const Color _incomingBubble = Color(0xFFEFF1F5);
  static const Color _outgoingBubble = Color(0xFFE8E3FF);
  static const Color _activeGreen = Color(0xFF4ED0AF);
  static const Duration _groupWindow = Duration(minutes: 4);
  static const double _messageHorizontalInset = 8;
  static const double _receiverAvatarRadius = 13;
  static const double _receiverAvatarSlotWidth = _receiverAvatarRadius * 2;
  static const double _receiverAvatarGap = 8;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(_handleComposerChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollChanged);
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

  String _formatBstTime(DateTime timestamp) {
    final bstTime = timestamp.toUtc().add(const Duration(hours: 6));
    return '${DateFormat('hh:mm a').format(bstTime)} BST';
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
    _messageController.removeListener(_handleComposerChanged);
    _scrollController.removeListener(_handleScrollChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasTypedText) {
      setState(() => _hasTypedText = hasText);
    }
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final shouldShow = max - current > 160;
    if (shouldShow != _showJumpToRecent) {
      setState(() => _showJumpToRecent = shouldShow);
    }
  }

  bool _isNearRecent() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    return (max - current) <= 160;
  }

  void _scrollToRecent({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }

    _scrollController.jumpTo(target);
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
                final sortedMessages = [...messages]
                  ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

                final currentUsername =
                    context.read<AuthProvider>().currentUsername ?? '';

                if (sortedMessages.length != _lastMessageCount) {
                  final hadMessages = _lastMessageCount > 0;
                  _lastMessageCount = sortedMessages.length;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || sortedMessages.isEmpty) return;
                    final latest = sortedMessages.last;
                    final shouldAutoScroll =
                        !hadMessages || _isNearRecent() || latest.sender == currentUsername;
                    if (shouldAutoScroll) {
                      _scrollToRecent(animated: hadMessages);
                    }
                  });
                }

                if (sortedMessages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start the conversation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: sortedMessages.length,
                      itemBuilder: (context, index) {
                        final message = sortedMessages[index];
                        final previous = index > 0 ? sortedMessages[index - 1] : null;
                        final next = index < sortedMessages.length - 1
                            ? sortedMessages[index + 1]
                            : null;

                        final groupedWithPrevious = previous != null &&
                            previous.sender == message.sender &&
                            message.sentAt.difference(previous.sentAt).abs() <= _groupWindow;
                        final groupedWithNext = next != null &&
                            next.sender == message.sender &&
                            next.sentAt.difference(message.sentAt).abs() <= _groupWindow;

                        return _buildMessageBubble(
                          context,
                          message,
                          isStartOfGroup: !groupedWithPrevious,
                          isEndOfGroup: !groupedWithNext,
                        );
                      },
                    ),
                    if (_showJumpToRecent)
                      Positioned(
                        right: 0,
                        left: 0,
                        bottom: 14,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _scrollToRecent(),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E3440),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.keyboard_double_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: _hasTypedText
                        ? GestureDetector(
                            key: const ValueKey('send-button'),
                            onTap: _sendMessage,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _activeGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : GestureDetector(
                            key: const ValueKey('voice-button'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Voice recording will be added soon.'),
                                ),
                              );
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8DEE8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: Color(0xFF566176),
                                size: 18,
                              ),
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToRecent());
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message, {
    required bool isStartOfGroup,
    required bool isEndOfGroup,
  }) {
    final isFromMe = message.sender == context.read<AuthProvider>().currentUsername;

    final bubbleRadius = BorderRadius.only(
      topLeft: Radius.circular(isFromMe ? 14 : (isStartOfGroup ? 14 : 6)),
      topRight: Radius.circular(isFromMe ? (isStartOfGroup ? 14 : 6) : 14),
      bottomLeft: Radius.circular(isFromMe ? 14 : (isEndOfGroup ? 14 : 6)),
      bottomRight: Radius.circular(isFromMe ? (isEndOfGroup ? 14 : 6) : 14),
    );

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFromMe ? _outgoingBubble : _incomingBubble,
        borderRadius: bubbleRadius,
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
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF6B7689),
                    ),
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
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Color(0xFF4B5567),
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
    );

    if (isFromMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _messageHorizontalInset,
            isStartOfGroup ? 8 : 2,
            _messageHorizontalInset,
            isEndOfGroup ? 8 : 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bubble,
              if (isEndOfGroup)
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 4),
                  child: Text(
                    _formatBstTime(message.sentAt),
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _messageHorizontalInset,
          isStartOfGroup ? 8 : 2,
          _messageHorizontalInset,
          isEndOfGroup ? 8 : 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEndOfGroup)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _buildReceiverAvatar(),
              )
            else
              const SizedBox(width: _receiverAvatarSlotWidth),
            const SizedBox(width: _receiverAvatarGap),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bubble,
                  if (isEndOfGroup)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 4),
                      child: Text(
                        _formatBstTime(message.sentAt),
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverAvatar() {
    final fallbackLetter = widget.partner.isNotEmpty ? widget.partner[0].toUpperCase() : '?';
    return FutureBuilder<String?>(
      future: _partnerAvatarFuture,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        return CircleAvatar(
          radius: _receiverAvatarRadius,
          backgroundColor: const Color(0xFFD5DDE8),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Text(
                  fallbackLetter,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5A6679),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        );
      },
    );
  }
}
