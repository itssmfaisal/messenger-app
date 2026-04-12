import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers.dart';
import 'screens/auth_screens.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService)..init(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MessagesProvider>(
          create: (context) => MessagesProvider(apiService: apiService),
          update: (context, authProvider, messagesProvider) {
            if (authProvider.isAuthenticated && messagesProvider != null) {
              if (messagesProvider.webSocketService == null) {
                messagesProvider.initWebSocket(
                  authProvider.token!,
                  authProvider.currentUsername!,
                );
              }
            }
            return messagesProvider ?? MessagesProvider(apiService: apiService);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (context) => ProfileProvider(apiService: apiService),
          update: (context, authProvider, profileProvider) {
            if (authProvider.isAuthenticated && profileProvider != null) {
              profileProvider.loadProfile();
            }
            return profileProvider ?? ProfileProvider(apiService: apiService);
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, MessagesProvider, PresenceProvider>(
          create: (context) => PresenceProvider(apiService: apiService),
          update: (context, authProvider, messagesProvider, presenceProvider) {
            if (authProvider.isAuthenticated && presenceProvider != null && messagesProvider.webSocketService != null) {
              presenceProvider.initWebSocket(messagesProvider.webSocketService!);
              presenceProvider.loadOnlineUsers();
            }
            return presenceProvider ?? PresenceProvider(apiService: apiService);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Messenger',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF146a65),
        primary: const Color(0xFF146a65),
        secondary: const Color(0xFF6d4ea3),
        tertiary: const Color(0xFF715578),
        error: const Color(0xFFac3434),
        surface: const Color(0xFFf8fafb),
        onSurface: const Color(0xFF2d3435),
      ),
      fontFamily: 'Manrope',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return const MainApp();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const Color _activeNav = Color(0xFF35BE86);
  static const Color _inactiveNav = Color(0xFF6A7890);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MessagesProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MessagesScreen(),
      Container(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Contacts',
                icon: Icons.people_outline_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Profile',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isActive = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive ? _activeNav : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : _inactiveNav,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? _activeNav : _inactiveNav,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
