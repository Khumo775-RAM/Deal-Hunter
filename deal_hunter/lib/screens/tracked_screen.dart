import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/deals_provider.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/tracked_game_tile.dart';
import 'login_screen.dart';

class TrackedScreen extends StatefulWidget {
  const TrackedScreen({super.key});

  @override
  State<TrackedScreen> createState() => _TrackedScreenState();
}

class _TrackedScreenState extends State<TrackedScreen> {
  String _lastCurrency = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();
    final c        = context.colors;

    // Re-fetch when currency changes.
    final currency = context.watch<DealsProvider>().currency;
    if (_lastCurrency.isNotEmpty && currency != _lastCurrency) {
      _lastCurrency = currency;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => provider.fetchTrackedGames(),
      );
    } else if (_lastCurrency.isEmpty) {
      _lastCurrency = currency;
    }

    // If session expired (401), sign out and go to login
    if (provider.error != null &&
        provider.error!.contains('Session expired')) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<AuthProvider>().logout();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        title: Text('My Tracked Games',
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textSecondary),
            onPressed: provider.fetchTrackedGames,
          ),
        ],
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : provider.error != null
              ? _ErrorView(
                  message: provider.error!,
                  onRetry: provider.fetchTrackedGames,
                )
              : provider.games.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 64, color: c.textFaint),
                          const SizedBox(height: 16),
                          Text('No games tracked yet',
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text(
                            'Search for a game and tap Track\nto add it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: c.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: c.accent,
                      onRefresh: provider.fetchTrackedGames,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.games.length,
                        itemBuilder: (_, i) {
                          final game = provider.games[i];
                          return TrackedGameTile(
                            game: game,
                            onDelete: () async {
                              final title = game.title;
                              final ok = await provider.untrackGame(game.gameId);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? '"$title" removed from tracking.'
                                      : provider.error ?? 'Error'),
                                  backgroundColor: ok
                                      ? Colors.green
                                      : Colors.red.shade700,
                                ),
                              );
                              provider.clearMessages();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textHigh)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
