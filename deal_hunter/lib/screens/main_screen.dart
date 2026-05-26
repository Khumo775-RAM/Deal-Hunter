import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deals_provider.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_colors.dart';
import 'deals_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tracked_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DealsScreen(),
    SearchScreen(),
    TrackedScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealsProvider>().init();
      context.read<TrackingProvider>().fetchTrackedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: c.surface,
        indicatorColor: c.accentNavIndicator,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer, color: c.accent),
            label: 'Deals',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: c.accent),
            label: 'Search',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: c.accent),
            label: 'Tracked',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: c.accent),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
