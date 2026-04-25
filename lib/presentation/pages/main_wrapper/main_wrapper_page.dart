import 'package:flutter/material.dart';
import 'package:messenger_app/presentation/profile_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
// Import your actual screen files here
// import 'package:your_app/presentation/pages/message/message_screen.dart';

class MainWrapperPage extends StatefulWidget {
  const MainWrapperPage({super.key});

  @override
  State<MainWrapperPage> createState() => _MainWrapperPageState();
}

class _MainWrapperPageState extends State<MainWrapperPage> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      const Center(
        child: Text("Messages Screen"),
      ), // Replace with MessageScreen()
      const Center(child: Text("Calls Screen")), // Replace with CallsScreen()
      const Center(child: Text("Feed Screen")), // Replace with FeedScreen()
      const ProfileScreen(), // Replace with ProfileScreen()
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble_outline),
        //activeIcon: const Icon(Icons.chat_bubble),
        title: ("Message"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.call_outlined),
        //activeIcon: const Icon(Icons.call),
        title: ("Call"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.rss_feed),
        title: ("Feed"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        //activeIcon: const Icon(Icons.person),
        title: ("Profile"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
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
        bevel: 12, // Depth of the Neumorphic effect
        curveType: CurveType.concave,
        showSubtitleText:
            false, // Ensures labels are hidden even if titles aren't empty
      ),
      decoration: const NavBarDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      //popAllScreensOnTapOfSelectedTab: true,
      navBarStyle: NavBarStyle.style9, // Style 9 is clean and modern
    );
  }
}
