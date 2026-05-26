class SearchResult {
  final String gameID;
  final String title;
  final String cheapest;
  final String thumb;
  final String currency;

  const SearchResult({
    required this.gameID,
    required this.title,
    required this.cheapest,
    required this.thumb,
    this.currency = 'USD',
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        gameID: json['gameID'] ?? '',
        title: json['title'] ?? '',
        cheapest: json['cheapest'] ?? '0',
        thumb: json['thumb'] ?? '',
        currency: json['currency'] ?? 'USD',
      );
}

class TrackedGame {
  final String title;
  final String gameId;
  final String trackedAt;
  final String thumb;
  final String currency;
  final double? cheapestPrice;
  final double? retailPrice;
  final String? cheapestStore;
  final String dealUrl;

  const TrackedGame({
    required this.title,
    required this.gameId,
    required this.trackedAt,
    this.thumb = '',
    this.currency = 'USD',
    this.cheapestPrice,
    this.retailPrice,
    this.cheapestStore,
    this.dealUrl = '',
  });

  factory TrackedGame.fromJson(Map<String, dynamic> json) => TrackedGame(
        title: json['title'] ?? '',
        gameId: json['gameId'] ?? '',
        trackedAt: json['tracked_at'] ?? '',
        thumb: json['thumb'] ?? '',
        currency: json['currency'] ?? 'USD',
        cheapestPrice: (json['cheapestPrice'] as num?)?.toDouble(),
        retailPrice: (json['retailPrice'] as num?)?.toDouble(),
        cheapestStore: json['cheapestStore'] as String?,
        dealUrl: json['dealUrl'] ?? '',
      );
}
