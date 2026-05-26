import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../screens/game_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';
import '../utils/url_utils.dart';

class TrackedGameTile extends StatelessWidget {
  const TrackedGameTile({
    super.key,
    required this.game,
    required this.onDelete,
  });

  final TrackedGame game;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c        = context.colors;
    final hasPrice = game.cheapestPrice != null;
    final isFree   = hasPrice && game.cheapestPrice == 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameDetailScreen(
            gameId: game.gameId,
            title: game.title,
            thumb: game.thumb,
            dealSalePrice: game.cheapestPrice,
            dealNormalPrice: game.retailPrice,
            dealStore: game.cheapestStore,
            dealCurrency: game.currency,
            dealUrl: game.dealUrl,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: game.thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.thumb,
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(c),
                      errorWidget: (_, __, ___) => _placeholder(c),
                    )
                  : _placeholder(c),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    if (hasPrice) ...[
                      Row(
                        children: [
                          Text(
                            isFree
                                ? 'FREE'
                                : '${currencySymbol(game.currency)}${game.cheapestPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          if (!isFree &&
                              game.retailPrice != null &&
                              game.retailPrice! > game.cheapestPrice!) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${currencySymbol(game.currency)}${game.retailPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: c.textMuted),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (game.cheapestStore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accentSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            game.cheapestStore!,
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ] else
                      Text('No deals found',
                          style: TextStyle(
                              color: c.textMuted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      'Since ${_formatDate(game.trackedAt)}',
                      style: TextStyle(color: c.textDisabled, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (game.dealUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => openDealUrl(context, game.dealUrl),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
                    child: Icon(Icons.open_in_new,
                        color: c.accent, size: 20),
                  ),
                ),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 12, 12),
                  child: Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 22),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppColors c) => Container(
        width: 110,
        height: 90,
        color: c.background,
        child: Icon(Icons.videogame_asset_outlined,
            color: c.textFaint, size: 32),
      );

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day} ${_month(dt.month)} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  void _confirmDelete(BuildContext context) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Remove Game',
            style: TextStyle(color: c.textPrimary)),
        content: Text('Remove "${game.title}" from tracking?',
            style: TextStyle(color: c.textHigh)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
