import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_state.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_bloc.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_event.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/data/models/chat_message.dart';
import 'package:messenger_app/data/models/presence.dart';
import 'package:messenger_app/data/services/websocket_service.dart';
import 'package:messenger_app/presentation/pages/chat_list/chat_list_screen.dart';
import 'package:messenger_app/presentation/profile_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class MainWrapperPage extends StatefulWidget {
  final WebSocketService webSocketService;

  const MainWrapperPage({super.key, required this.webSocketService});

  @override
  State<MainWrapperPage> createState() => _MainWrapperPageState();
}

class _MainWrapperPageState extends State<MainWrapperPage> {
  late PersistentTabController _controller;
  late StreamSubscription<ChatMessage> _messageSub;
  late StreamSubscription<Map<String, dynamic>> _statusSub;
  late StreamSubscription<PresenceStatus> _presenceSub;
  late StreamSubscription<String> _errorSub;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final token = await widget.webSocketService.getToken();
    if (token == null) return;

    await widget.webSocketService.connect(token);
    widget.webSocketService.join();

    _messageSub = widget.webSocketService.messageStream.listen((message) {
      if (mounted) {
        context.read<ChatDetailBloc>().add(MessageReceived(message));
      }
    });

    _statusSub = widget.webSocketService.statusUpdateStream.listen((update) {
      if (!mounted) return;
      final messageId = update['messageId'] as int;
      final status = update['status'] as String;
      final messageStatus = switch (status) {
        'DELIVERED' => MessageStatus.delivered,
        'SEEN' => MessageStatus.seen,
        _ => MessageStatus.sent,
      };
      context.read<ChatDetailBloc>().add(
            MessageStatusUpdated(messageId, messageStatus),
          );
    });

    _presenceSub = widget.webSocketService.presenceStream.listen((presence) {
      if (mounted) {
        context.read<ChatDetailBloc>().add(
              PartnerPresenceChanged(presence.online),
            );
      }
    });

    _errorSub = widget.webSocketService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageSub.cancel();
    _statusSub.cancel();
    _presenceSub.cancel();
    _errorSub.cancel();
    widget.webSocketService.disconnect();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      const ChatListScreen(),
      const Center(child: Text("Calls Screen")),
      const Center(child: Text("Feed Screen")),
      const ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble_outline),
        title: "Message",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.call_outlined),
        title: "Call",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.rss_feed),
        title: "Feed",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        title: "Profile",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          widget.webSocketService.disconnect();
        }
      },
      child: PersistentTabView(
        context,
        controller: _controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        confineToSafeArea: true,
        backgroundColor: Colors.white,
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        neumorphicProperties: const NeumorphicProperties(
          shape: BoxShape.rectangle,
          border: BoxBorder.symmetric(),
          bevel: 12,
          curveType: CurveType.concave,
          showSubtitleText: false,
        ),
        decoration: const NavBarDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        navBarStyle: NavBarStyle.style9,
      ),
    );
  }
}
