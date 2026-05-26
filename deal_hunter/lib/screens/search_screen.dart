import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/game.dart';
import '../providers/deals_provider.dart';
import '../providers/tracking_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/search_result_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _api = ApiService();

  List<SearchResult> _results = [];
  bool _isLoading = false;
  bool _searched = false;
  String? _error;
  Timer? _debounce;
  String _lastCurrency = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currency = StorageService.getCurrency();
      final data = await _api.get(
        ApiConfig.search,
        queryParams: {'title': q, 'currency': currency},
      ) as List;
      setState(() {
        _results = data
            .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        _searched = true;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.statusCode == 404 ? 'No games found for "$q"' : e.message;
        _results = [];
        _searched = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Network error. Is the server running?';
        _results = [];
        _searched = true;
      });
    }

    setState(() => _isLoading = false);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.read<TrackingProvider>();
    final c        = context.colors;

    // Re-run the current search whenever the currency changes.
    final currency = context.watch<DealsProvider>().currency;
    if (_searched && currency != _lastCurrency) {
      _lastCurrency = currency;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _search(_searchCtrl.text),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        title: Text('Search Games',
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onChanged,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a game...',
                hintStyle: TextStyle(color: c.textMuted),
                prefixIcon: Icon(Icons.search, color: c.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: c.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.accent, width: 1.5),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search is case-sensitive. Try "Cyberpunk" and "cyberpunk" for different results.',
                    style: TextStyle(color: c.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: c.accent))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary)))
                    : !_searched
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videogame_asset_outlined,
                                    size: 56, color: c.textFaint),
                                const SizedBox(height: 12),
                                Text('Type a game name to search',
                                    style:
                                        TextStyle(color: c.textMuted)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => SearchResultCard(
                              result: _results[i],
                              onTrack: () async {
                                final ok = await tracking.trackGame(
                                    _results[i].title, _results[i].gameID);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? tracking.success ??
                                            'Game tracked!'
                                        : tracking.error ?? 'Error'),
                                    backgroundColor:
                                        ok ? Colors.green : Colors.red.shade700,
                                  ),
                                );
                                tracking.clearMessages();
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
