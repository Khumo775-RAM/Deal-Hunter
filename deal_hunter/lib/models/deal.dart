class Deal {
  final String title;
  final double salePrice;
  final double normalPrice;
  final double discount;
  final String store;
  final String currency;
  final String dealID;
  final String dealUrl;
  final String gameID;
  final String? steamAppID;
  final String thumb;
  final String lastSaleDate;

  const Deal({
    required this.title,
    required this.salePrice,
    required this.normalPrice,
    required this.discount,
    required this.store,
    required this.currency,
    this.dealID = '',
    this.dealUrl = '',
    this.gameID = '',
    this.steamAppID,
    this.thumb = '',
    this.lastSaleDate = '',
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        title: json['title'] ?? '',
        salePrice: (json['salePrice'] ?? 0).toDouble(),
        normalPrice: (json['normalPrice'] ?? 0).toDouble(),
        discount: (json['discount'] ?? 0).toDouble(),
        store: json['store'] ?? '',
        currency: json['currency'] ?? 'USD',
        dealID: json['dealID'] ?? '',
        dealUrl: json['dealUrl'] ?? '',
        gameID: json['gameID'] ?? '',
        steamAppID: json['steamAppID'] as String?,
        thumb: json['thumb'] ?? '',
        lastSaleDate: json['lastSaleDate'] ?? '',
      );
}
