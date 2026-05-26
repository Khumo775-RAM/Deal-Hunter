import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/deal.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DealsProvider extends ChangeNotifier {
  static const int _pageSize = 20;

  List<Deal> _deals = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  String _currency    = 'USD';
  String _sortBy      = 'discount';
  double _minDiscount = 0;
  String? _storeId;

  List<Deal> get deals         => _deals;
  bool get isLoading           => _isLoading;
  bool get isLoadingMore       => _isLoadingMore;
  bool get hasMore             => _hasMore;
  String? get error            => _error;
  String get currency          => _currency;
  String get sortBy            => _sortBy;
  double get minDiscount       => _minDiscount;
  String? get storeId          => _storeId;

  final _api = ApiService();

  void init() {
    _currency = StorageService.getCurrency();
    fetchDeals();
  }

  Future<void> fetchDeals() async {
    _isLoading = true;
    _isLoadingMore = false;
    _hasMore = true;
    _page = 0;
    _error = null;
    notifyListeners();

    try {
      final results = await _fetchPage(0);
      _deals = results;
      _hasMore = results.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore == true || _hasMore == false || _isLoading == true) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final results = await _fetchPage(nextPage);
      _deals = [..._deals, ...results];
      _page = nextPage;
      _hasMore = results.length >= _pageSize;
    } catch (_) {
      // Silently fail — existing deals remain visible.
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<List<Deal>> _fetchPage(int page) async {
    final params = <String, String>{
      'currency': _currency,
      'sort_by': _sortBy,
      'page': page.toString(),
      'page_size': _pageSize.toString(),
      if (_minDiscount > 0) 'min_discount': _minDiscount.toStringAsFixed(0),
      if (_storeId != null) 'store_id': _storeId!,
    };
    final data = await _api.get(ApiConfig.deals, queryParams: params) as List;
    return data.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
  }

  void updateFilters({
    String? currency,
    String? sortBy,
    double? minDiscount,
    String? storeId,
    bool clearStore = false,
  }) {
    if (currency != null) _currency = currency;
    if (sortBy != null) _sortBy = sortBy;
    if (minDiscount != null) _minDiscount = minDiscount;
    if (clearStore) {
      _storeId = null;
    } else if (storeId != null) {
      _storeId = storeId;
    }
    fetchDeals();
  }

  void updateCurrency(String currency) {
    _currency = currency;
    StorageService.saveCurrency(currency);
    fetchDeals();
  }
}
