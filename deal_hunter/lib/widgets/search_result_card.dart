import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../screens/game_detail_screen.dart';
import '../theme/app_colors.dart';
import '../utils/currency_utils.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTrack,
  });

  final SearchResult result;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameDetailScreen(
            gameId: result.gameID,
            title: result.title,
            thumb: result.thumb,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: result.thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: result.thumb,
                      width: 90,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(c),
                      errorWidget: (_, __, ___) => _placeholder(c),
                    )
                  : _placeholder(c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ${currencySymbol(result.currency)}${result.cheapest}',
                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTrack,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Track',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.onAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppColors c) => Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.videogame_asset_outlined,
            color: c.textFaint, size: 24),
      );
}
