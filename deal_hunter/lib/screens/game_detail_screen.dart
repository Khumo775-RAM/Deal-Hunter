import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_detail.dart';
import '../providers/tracking_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';
import '../utils/steam_image_utils.dart';
import '../utils/url_utils.dart';

class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({
    super.key,
    required this.gameId,
    required this.title,
    this.thumb = '',
    // Deal-specific values passed from the card that was tapped.
    this.dealSalePrice,
    this.dealNormalPrice,
    this.dealStore,
    this.dealCurrency,
    this.dealDiscount,
    this.dealUrl = '',
  });

  final String gameId;
  final String title;
  final String thumb;
  final double? dealSalePrice;
  final double? dealNormalPrice;
  final String? dealStore;
  final String? dealCurrency;
  final double? dealDiscount;
  final String dealUrl;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  GameDetail? _detail;
  bool _isLoading = true;
  String? _error;

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final currency = StorageService.getCurrency();
      final data =
          await _api.get('/games/${widget.gameId}?currency=$currency')
              as Map<String, dynamic>;
      setState(() {
        _detail = GameDetail.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : _DetailBody(
                  detail: _detail!,
                  gameId: widget.gameId,
                  fallbackThumb: widget.thumb,
                  dealSalePrice: widget.dealSalePrice,
                  dealNormalPrice: widget.dealNormalPrice,
                  dealStore: widget.dealStore,
                  dealCurrency: widget.dealCurrency,
                  dealDiscount: widget.dealDiscount,
                  dealUrl: widget.dealUrl,
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail body
// ─────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.gameId,
    this.fallbackThumb = '',
    this.dealSalePrice,
    this.dealNormalPrice,
    this.dealStore,
    this.dealCurrency,
    this.dealDiscount,
    this.dealUrl = '',
  });
  final GameDetail detail;
  final String gameId;
  final String fallbackThumb;
  final double? dealSalePrice;
  final double? dealNormalPrice;
  final String? dealStore;
  final String? dealCurrency;
  final double? dealDiscount;
  final String dealUrl;

  @override
  Widget build(BuildContext context) {
    final c        = context.colors;
    final hasSteam  = detail.steamAppID != null;
    final thumbForPlaceholder =
        fallbackThumb.isNotEmpty ? fallbackThumb : detail.thumb;

    // Hero: high-res library_hero → API header → standard header.jpg → thumb
    final heroUrls = <String>[
      steamHeroUrl(detail.steamAppID),
      if (detail.headerImage.isNotEmpty) detail.headerImage,
      steamHeaderUrl(detail.steamAppID),
      thumbForPlaceholder,
    ].where((u) => u.isNotEmpty).toSet().toList();
    final hasHeader = heroUrls.isNotEmpty;

    final showSalePrice   = dealSalePrice   ?? detail.cheapestPrice;
    final showRetailPrice = dealNormalPrice  ?? detail.retailPrice;
    final showStore       = dealStore        ?? detail.cheapestStore;
    final showCurrency    = dealCurrency     ?? detail.currency;
    final showDiscount    = dealDiscount;
    // Prefer the deal link from the tapped card; fall back to API cheapest deal.
    final showDealUrl =
        dealUrl.isNotEmpty ? dealUrl : detail.dealUrl;

    return CustomScrollView(
      slivers: [
        // ── Hero header image ──────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: c.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: hasHeader
                ? _SafeNetworkImage(urls: heroUrls)
                : _headerPlaceholder(context, thumbForPlaceholder),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────
                Text(detail.title,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // ── Price ──────────────────────────────────
                if (showSalePrice != null)
                  _PriceCard(
                    salePrice: showSalePrice,
                    retailPrice: showRetailPrice,
                    store: showStore,
                    currency: showCurrency,
                    discount: showDiscount,
                    dealUrl: showDealUrl,
                  ),
                const SizedBox(height: 16),

                // ── Description ────────────────────────────
                if (detail.description.isNotEmpty) ...[
                  _SectionTitle('About'),
                  const SizedBox(height: 8),
                  Text(detail.description,
                      style: TextStyle(
                          color: c.textHigh, fontSize: 13, height: 1.6)),
                  const SizedBox(height: 16),
                ],

                // ── Genres ─────────────────────────────────
                if (detail.genres.isNotEmpty) ...[
                  _SectionTitle('Genres'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: detail.genres
                        .map((g) => _Chip(label: g))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Screenshots ────────────────────────────
                if (detail.screenshots.isNotEmpty) ...[
                  _SectionTitle('Screenshots'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.screenshots.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _ScreenshotViewer(
                              screenshots: detail.screenshots,
                              initialIndex: i,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl: detail.screenshots[i],
                                height: 140,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                placeholder: (_, __) => Container(
                                  width: 220,
                                  color: c.surface,
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Details ────────────────────────────────
                _SectionTitle('Details'),
                const SizedBox(height: 8),
                _DetailCard(detail: detail),
                const SizedBox(height: 24),

                // ── Track button ───────────────────────────
                _TrackButton(gameId: gameId, title: detail.title),
                const SizedBox(height: 32),

                if (!hasSteam)
                  Center(
                    child: Text(
                      'No Steam data available for this title.',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerPlaceholder(BuildContext context, String thumb) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb.isNotEmpty)
          CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover)
        else
          Container(color: c.surface),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                c.background.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Price card
// ─────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.salePrice,
    required this.currency,
    this.retailPrice,
    this.store,
    this.discount,
    this.dealUrl = '',
  });

  final double salePrice;
  final double? retailPrice;
  final String? store;
  final String currency;
  final double? discount;
  final String dealUrl;

  String _fmt(double price) =>
      '${currencySymbol(currency)}${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isFree = salePrice == 0;

    final pct = discount != null
        ? discount!
        : (retailPrice != null && retailPrice! > 0)
            ? (1 - salePrice / retailPrice!) * 100
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFree ? 'FREE' : _fmt(salePrice),
                      style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    if (!isFree &&
                        retailPrice != null &&
                        retailPrice! > salePrice)
                      Text(
                        '${_fmt(retailPrice!)} retail',
                        style: TextStyle(
                            color: c.textMuted,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: c.textMuted),
                      ),
                    if (store != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.storefront_outlined,
                            size: 12, color: c.accent),
                        const SizedBox(width: 4),
                        Text(store!,
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ],
                ),
              ),
              if (!isFree && pct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.shade700.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '-${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
            ],
          ),
          if (dealUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => openDealUrl(context, dealUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  store != null
                      ? 'View deal on $store'
                      : 'View deal on store',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: c.onAccent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Details card (dev, publisher, release, metacritic)
// ─────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});
  final GameDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (detail.developers.isNotEmpty)
            _row(context, 'Developer', detail.developers.join(', ')),
          if (detail.publishers.isNotEmpty)
            _row(context, 'Publisher', detail.publishers.join(', ')),
          if (detail.releaseDate.isNotEmpty)
            _row(context, 'Released', detail.releaseDate),
          if (detail.metacriticScore != null)
            _row(context, 'Metacritic', '${detail.metacriticScore}/100',
                valueColor: detail.metacriticScore! >= 75
                    ? const Color(0xFF4CAF50)
                    : detail.metacriticScore! >= 50
                        ? Colors.orange
                        : Colors.red),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {Color? valueColor}) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Track button
// ─────────────────────────────────────────────────────────────
class _TrackButton extends StatelessWidget {
  const _TrackButton({required this.gameId, required this.title});
  final String gameId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c              = context.colors;
    final tracking       = context.read<TrackingProvider>();
    final alreadyTracked = tracking.games.any((g) => g.gameId == gameId);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: alreadyTracked
            ? null
            : () async {
                final ok = await tracking.trackGame(title, gameId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? tracking.success ?? 'Game tracked!'
                        : tracking.error ?? 'Error'),
                    backgroundColor:
                        ok ? Colors.green : Colors.red.shade700,
                  ),
                );
                tracking.clearMessages();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: alreadyTracked ? c.textFaint : c.accent,
          foregroundColor: alreadyTracked ? c.textSecondary : c.onAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(alreadyTracked ? Icons.check : Icons.favorite_outline),
        label: Text(
          alreadyTracked ? 'Already Tracked' : 'Track This Game',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          color: context.colors.accent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5));
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accentBorder),
      ),
      child: Text(label,
          style: TextStyle(
              color: c.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

/// Tries each URL in [urls] in order until one loads successfully.
class _SafeNetworkImage extends StatefulWidget {
  const _SafeNetworkImage({required this.urls});
  final List<String> urls;

  @override
  State<_SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<_SafeNetworkImage> {
  int _index = 0;

  void _tryNext() {
    if (_index < widget.urls.length - 1) {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (widget.urls.isEmpty) return Container(color: c.surface);

    final src = widget.urls[_index.clamp(0, widget.urls.length - 1)];

    return CachedNetworkImage(
      imageUrl: src,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: (_, __) => Container(color: c.surface),
      errorWidget: (_, __, ___) {
        if (_index < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tryNext();
          });
        }
        return Container(color: c.surface);
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 48),
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

// ─────────────────────────────────────────────────────────────
// Full-screen screenshot viewer with pinch-to-zoom + swipe
// ─────────────────────────────────────────────────────────────
class _ScreenshotViewer extends StatefulWidget {
  const _ScreenshotViewer({
    required this.screenshots,
    this.initialIndex = 0,
  });
  final List<String> screenshots;
  final int initialIndex;

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  late final PageController _pageCtrl;
  late int _current;

  late final List<TransformationController> _transforms;

  @override
  void initState() {
    super.initState();
    _current  = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _transforms = List.generate(
      widget.screenshots.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final t in _transforms) t.dispose();
    super.dispose();
  }

  void _resetZoom(int index) =>
      _transforms[index].value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_current + 1} / ${widget.screenshots.length}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<Matrix4>(
            valueListenable: _transforms[_current],
            builder: (_, matrix, __) {
              final isZoomed = matrix != Matrix4.identity();
              return isZoomed
                  ? IconButton(
                      icon: const Icon(Icons.zoom_out_map,
                          color: Colors.white70),
                      tooltip: 'Reset zoom',
                      onPressed: () => _resetZoom(_current),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.screenshots.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          return InteractiveViewer(
            transformationController: _transforms[i],
            minScale: 0.8,
            maxScale: 5.0,
            clipBehavior: Clip.none,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.screenshots[i],
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(color: c.accent),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white24, size: 64),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.screenshots.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.screenshots.length, (i) {
                    final active = i == _current;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.textDisabled,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            )
          : null,
    );
  }
}
