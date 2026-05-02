import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_bloc.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_event.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_state.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/data/models/chat_message.dart';

class ChatDetailScreen extends StatefulWidget {
  final String partnerUsername;

  const ChatDetailScreen({super.key, required this.partnerUsername});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isScrollingUp = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatDetailBloc>().add(OpenChat(widget.partnerUsername));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isScrollingUp) {
        _isScrollingUp = true;
        context.read<ChatDetailBloc>().add(LoadOlderMessages());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    context.read<ChatDetailBloc>().add(CloseChat());
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatDetailBloc>().add(SendMessage(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: BlocBuilder<ChatDetailBloc, ChatDetailState>(
          builder: (context, state) {
            String onlineStatus = '';
            if (state is ChatDetailLoaded) {
              onlineStatus = state.isPartnerOnline ? 'Online' : 'Offline';
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.partnerUsername),
                if (onlineStatus.isNotEmpty)
                  Text(
                    onlineStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: state is ChatDetailLoaded && state.isPartnerOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
              builder: (context, state) {
                if (state is ChatDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatDetailError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatDetailBloc>().add(
                                  OpenChat(widget.partnerUsername),
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ChatDetailLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No messages yet', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Say hello!', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    itemCount: state.messages.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isLoadingMore && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final realIndex = state.isLoadingMore ? index - 1 : index;
                      final message = state.messages[state.messages.length - 1 - realIndex];
                      return MessageBubble(message: message);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ChatDetailBloc, ChatDetailState>(
              builder: (context, state) {
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: state is ChatDetailLoaded ? _sendMessage : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender !=
        (message.recipient == message.sender
            ? message.recipient
            : message.sender);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight:
                      isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white70
                              : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    final iconSize = 14.0;
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.check, size: iconSize, color: Colors.white70);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: iconSize, color: Colors.white70);
      case MessageStatus.seen:
        return Icon(Icons.done_all, size: iconSize, color: Colors.lightBlueAccent);
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }
}
