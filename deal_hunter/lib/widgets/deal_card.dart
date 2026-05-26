import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../screens/game_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';
import '../utils/url_utils.dart';

class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final symbol = currencySymbol(deal.currency);

    return GestureDetector(
      onTap: deal.gameID.isNotEmpty
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameDetailScreen(
                    gameId: deal.gameID,
                    title: deal.title,
                    thumb: deal.thumb,
                    dealSalePrice: deal.salePrice,
                    dealNormalPrice: deal.normalPrice,
                    dealStore: deal.store,
                    dealCurrency: deal.currency,
                    dealDiscount: deal.discount,
                    dealUrl: deal.dealUrl,
                  ),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _Thumbnail(url: deal.thumb, steamAppID: deal.steamAppID ?? ''),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deal.salePrice == 0
                                ? 'FREE'
                                : '$symbol${deal.salePrice.toStringAsFixed(2)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (deal.normalPrice > deal.salePrice)
                          Flexible(
                            child: Text(
                              '$symbol${deal.normalPrice.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: c.textMuted),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _Tag(label: deal.store, color: c.accent),
                  ],
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DiscountBadge(discount: deal.discount),
              if (deal.dealUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => openDealUrl(context, deal.dealUrl),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.open_in_new,
                        color: c.accent, size: 20),
                  ),
                ),
              if (deal.lastSaleDate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    deal.lastSaleDate,
                    style: TextStyle(color: c.textDisabled, fontSize: 9),
                  ),
                ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, this.steamAppID = ''});
  final String url;
  final String steamAppID;

  String get _steamFallback => steamAppID.isNotEmpty && steamAppID != '0'
      ? 'https://cdn.akamai.steamstatic.com/steam/apps/$steamAppID/header.jpg'
      : '';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.horizontal(left: Radius.circular(16)),
      child: _MultiImage(
        primary: url,
        fallback: _steamFallback,
        width: 110,
        height: 80,
      ),
    );
  }
}

/// Tries [primary] first; if it fails or is empty, tries [fallback];
/// if that also fails, shows the placeholder icon.
class _MultiImage extends StatefulWidget {
  const _MultiImage({
    required this.primary,
    required this.fallback,
    required this.width,
    required this.height,
  });
  final String primary;
  final String fallback;
  final double width;
  final double height;

  @override
  State<_MultiImage> createState() => _MultiImageState();
}

class _MultiImageState extends State<_MultiImage> {
  bool _primaryFailed = false;

  Widget _placeholder() => Container(
        width: widget.width,
        height: widget.height,
        color: context.colors.background,
        child: Icon(Icons.videogame_asset_outlined,
            color: context.colors.textFaint, size: 32),
      );

  @override
  Widget build(BuildContext context) {
    final url = (!_primaryFailed && widget.primary.isNotEmpty)
        ? widget.primary
        : widget.fallback;

    if (url.isEmpty) return _placeholder();

    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        if (!_primaryFailed && url == widget.primary && widget.fallback.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _primaryFailed = true);
          });
          return _placeholder();
        }
        return _placeholder();
      },
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.discount});
  final double discount;

  @override
  Widget build(BuildContext context) {
    final color = discount >= 75
        ? Colors.red.shade400
        : discount >= 50
            ? Colors.orange.shade400
            : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '-${discount.toStringAsFixed(0)}%',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
