import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/game.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TrackingProvider extends ChangeNotifier {
  List<TrackedGame> _games = [];
  bool _isLoading = false;
  String? _error;
  String? _success;

  List<TrackedGame> get games => _games;
  bool get isLoading          => _isLoading;
  String? get error           => _error;
  String? get success         => _success;

  final _api = ApiService();

  Future<void> fetchTrackedGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currency = StorageService.getCurrency();
      final data = await _api.get(
        ApiConfig.track,
        auth: true,
        queryParams: {'currency': currency},
      ) as List;
      _games =
          data.map((e) => TrackedGame.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> trackGame(String title, String gameId) async {
    try {
      await _api.post(ApiConfig.track,
          body: {'title': title, 'gameId': gameId}, auth: true);
      _success = '"$title" added to your tracked games!';
      await fetchTrackedGames();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> untrackGame(String gameId) async {
    try {
      await _api.delete('${ApiConfig.track}$gameId', auth: true);
      _games.removeWhere((g) => g.gameId == gameId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _success = null;
  }
}
