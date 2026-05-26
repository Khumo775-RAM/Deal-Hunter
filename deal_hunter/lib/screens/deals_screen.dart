import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deals_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/deal_card.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  static const _stores = {
    'All':            null,
    'Steam':          '1',
    'GamersGate':     '2',
    'GMG':            '3',
    'Amazon':         '4',
    'GameStop':       '5',
    'Direct2Drive':   '6',
    'GOG':            '7',
    'Origin':         '8',
    'Get Games':      '9',
    'Shiny Loot':     '10',
    'Humble Store':   '11',
    'Desura':         '12',
    'Uplay':          '13',
    'IndieGameStand': '14',
    'Fanatical':      '15',
    'Gamesrocket':    '16',
    'Games Republic': '17',
    'SilaGames':      '18',
    'Playfield':      '19',
    'ImperialGames':  '20',
    'WinGameStore':   '21',
    'FunStockDigital':'22',
    'GameBillet':     '23',
    'Voidu':          '24',
    'Epic':           '25',
    'Razer Store':    '26',
    'Gamesplanet':    '27',
    'Gamesload':      '28',
    '2Game':          '29',
    'IndieGala':      '30',
    'Blizzard':       '31',
    'AllYouPlay':     '32',
    'DLGamer':        '33',
    'Noctre':         '34',
    'DreamGame':      '35',
  };

  static const _sorts = {
    'Best Discount': 'discount',
    'Lowest Price': 'price',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DealsProvider>();
    final c        = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        title: Text('DealHunter',
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CurrencyChip(currency: provider.currency),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(provider: provider),
          Expanded(
            child: provider.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: c.accent))
                : provider.error != null
                    ? _ErrorView(
                        message: provider.error!,
                        onRetry: provider.fetchDeals)
                    : provider.deals.isEmpty
                        ? _EmptyView(onRetry: provider.fetchDeals)
                        : _DealsList(provider: provider),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Deals list with infinite scroll
// ─────────────────────────────────────────────────────────────
class _DealsList extends StatefulWidget {
  const _DealsList({required this.provider});
  final DealsProvider provider;

  @override
  State<_DealsList> createState() => _DealsListState();
}

class _DealsListState extends State<_DealsList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 300) {
      widget.provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final c        = context.colors;
    return RefreshIndicator(
      color: c.accent,
      onRefresh: provider.fetchDeals,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: provider.deals.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == provider.deals.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: c.accent),
              ),
            );
          }
          return DealCard(deal: provider.deals[i]);
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.provider});
  final DealsProvider provider;

  String get _selectedStoreName {
    if (provider.storeId == null) return 'All Stores';
    return DealsScreen._stores.entries
        .firstWhere((e) => e.value == provider.storeId,
            orElse: () => const MapEntry('All Stores', null))
        .key;
  }

  void _showStorePicker(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            final c2 = ctx.colors;
            final filtered = DealsScreen._stores.entries
                .where((e) =>
                    e.key.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, scrollCtrl) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: c2.textDisabled,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Select Store',
                        style: TextStyle(
                            color: c2.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      autofocus: false,
                      style: TextStyle(color: c2.textPrimary),
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search stores...',
                        hintStyle: TextStyle(color: c2.textMuted),
                        prefixIcon: Icon(Icons.search, color: c2.textMuted),
                        filled: true,
                        fillColor: c2.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: c2.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        final isSelected = e.value == null
                            ? provider.storeId == null
                            : provider.storeId == e.value;
                        return ListTile(
                          leading: Icon(Icons.storefront_outlined,
                              color: isSelected ? c2.accent : c2.textMuted,
                              size: 20),
                          title: Text(e.key,
                              style: TextStyle(
                                  color: isSelected
                                      ? c2.accent
                                      : c2.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: c2.accent, size: 18)
                              : null,
                          onTap: () {
                            provider.updateFilters(
                              storeId: e.value,
                              clearStore: e.value == null,
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.background,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Sort: ',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ...DealsScreen._sorts.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(e.key),
                        selected: provider.sortBy == e.value,
                        onSelected: (_) =>
                            provider.updateFilters(sortBy: e.value),
                        selectedColor: c.accent,
                        backgroundColor: c.surface,
                        labelStyle: TextStyle(
                          color: provider.sortBy == e.value
                              ? c.onAccent
                              : c.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showStorePicker(context),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: provider.storeId != null
                    ? Border.all(color: c.accent, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined,
                      color: c.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedStoreName,
                      style: TextStyle(
                        color: provider.storeId != null
                            ? c.accent
                            : c.textSecondary,
                        fontSize: 13,
                        fontWeight: provider.storeId != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, color: c.textMuted, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Min discount: ',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: provider.minDiscount,
                  min: 0,
                  max: 90,
                  divisions: 9,
                  activeColor: c.accent,
                  inactiveColor: c.surface,
                  label: '${provider.minDiscount.toInt()}%',
                  onChanged: (v) => provider.updateFilters(minDiscount: v),
                ),
              ),
              Text('${provider.minDiscount.toInt()}%',
                  style: TextStyle(color: c.textHigh, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(currency,
          style: TextStyle(
              color: c.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
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
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied_outlined,
              color: c.textMuted, size: 56),
          const SizedBox(height: 12),
          Text('No deals found for these filters',
              style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Clear filters',
                style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
  }
}
