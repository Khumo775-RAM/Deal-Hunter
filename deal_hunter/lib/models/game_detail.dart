class GameDetail {
  final String title;
  final String gameId;
  final String thumb;
  final String? steamAppID;
  final String currency;
  final double? cheapestPrice;
  final double? retailPrice;
  final String? cheapestStore;
  final String dealUrl;

  // Steam data
  final String description;
  final String headerImage;
  final List<String> genres;
  final List<String> developers;
  final List<String> publishers;
  final String releaseDate;
  final int? metacriticScore;
  final List<String> screenshots;
  final String steamPrice;
  final int steamDiscount;

  const GameDetail({
    required this.title,
    required this.gameId,
    this.thumb = '',
    this.steamAppID,
    this.currency = 'USD',
    this.cheapestPrice,
    this.retailPrice,
    this.cheapestStore,
    this.dealUrl = '',
    this.description = '',
    this.headerImage = '',
    this.genres = const [],
    this.developers = const [],
    this.publishers = const [],
    this.releaseDate = '',
    this.metacriticScore,
    this.screenshots = const [],
    this.steamPrice = '',
    this.steamDiscount = 0,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) => GameDetail(
        title: json['title'] ?? '',
        gameId: json['gameId'] ?? '',
        thumb: json['thumb'] ?? '',
        steamAppID: json['steamAppID'] as String?,
        currency: json['currency'] as String? ?? 'USD',
        cheapestPrice: (json['cheapestPrice'] as num?)?.toDouble(),
        retailPrice: (json['retailPrice'] as num?)?.toDouble(),
        cheapestStore: json['cheapestStore'] as String?,
        dealUrl: json['dealUrl'] ?? '',
        description: json['description'] ?? '',
        headerImage: json['headerImage'] ?? '',
        genres: List<String>.from(json['genres'] ?? []),
        developers: List<String>.from(json['developers'] ?? []),
        publishers: List<String>.from(json['publishers'] ?? []),
        releaseDate: json['releaseDate'] ?? '',
        metacriticScore: json['metacriticScore'] as int?,
        screenshots: List<String>.from(json['screenshots'] ?? []),
        steamPrice: json['steamPrice'] ?? '',
        steamDiscount: (json['steamDiscount'] as num?)?.toInt() ?? 0,
      );
}
