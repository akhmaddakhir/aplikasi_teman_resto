import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/partner_model.dart';
import '../models/user_model.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  static const String _userKey = 'logged_in_user';
  static const String _loginHistoryKey = 'login_history';
  static const String _selectedLocationKey = 'selected_location';
  static const String _recentViewedRestaurantsKey = 'recent_viewed_restaurants';
  static const String _recentSearchesKey = 'recent_searches';

  factory SessionService() {
    return _instance;
  }

  SessionService._internal();

  /// Save user session
  Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);

      final location = user.location?.trim();
      if (location != null && location.isNotEmpty) {
        await prefs.setString(_selectedLocationKey, location);
      }

      // Tambah ke login history
      await _addLoginHistory(user);
    } catch (e) {
      throw Exception('Save session failed: ${e.toString()}');
    }
  }

  /// Get user session
  Future<UserModel?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString(_userKey);

      if (userJson == null) {
        return null;
      }

      Map<String, dynamic> userMap = jsonDecode(userJson);
      return UserModel.fromJson(userMap);
    } catch (e) {
      throw Exception('Get session failed: ${e.toString()}');
    }
  }

  Future<void> saveSelectedLocation(String location) async {
    try {
      final selectedLocation = location.trim();
      if (selectedLocation.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLocationKey, selectedLocation);

      final user = await getUserSession();
      if (user != null) {
        await prefs.setString(
          _userKey,
          jsonEncode(user.copyWith(location: selectedLocation).toJson()),
        );
      }
    } catch (e) {
      throw Exception('Save selected location failed: ${e.toString()}');
    }
  }

  Future<String?> getSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final location = prefs.getString(_selectedLocationKey)?.trim();
      return location?.isNotEmpty == true ? location : null;
    } catch (e) {
      throw Exception('Get selected location failed: ${e.toString()}');
    }
  }

  Future<void> saveRecentViewedRestaurant(PartnerModel restaurant) async {
    try {
      if (restaurant.id.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final current = await getRecentViewedRestaurants();
      final updated = [
        restaurant,
        ...current.where((item) => item.id != restaurant.id),
      ].take(6).toList();

      final payload = updated.map((item) => item.toFirestore()).toList();
      await prefs.setString(_recentViewedRestaurantsKey, jsonEncode(payload));
    } catch (e) {
      throw Exception('Save recent viewed restaurant failed: ${e.toString()}');
    }
  }

  Future<List<PartnerModel>> getRecentViewedRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_recentViewedRestaurantsKey);
      if (json == null) return [];

      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PartnerModel.fromFirestore)
          .where((item) => item.id.trim().isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Get recent viewed restaurants failed: ${e.toString()}');
    }
  }

  /// Remove restaurant from recent viewed
  Future<void> removeRecentViewedRestaurant(String restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getRecentViewedRestaurants();
      final updated = current.where((item) => item.id != restaurantId).toList();

      final payload = updated.map((item) => item.toFirestore()).toList();
      await prefs.setString(_recentViewedRestaurantsKey, jsonEncode(payload));
    } catch (e) {
      throw Exception(
          'Remove recent viewed restaurant failed: ${e.toString()}');
    }
  }

  /// Save recent search
  Future<void> saveRecentSearch(String query) async {
    try {
      if (query.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final current = await getRecentSearches();

      // Remove duplicate if exists
      current.removeWhere((item) => item == query.trim());

      // Add to beginning
      current.insert(0, query.trim());

      // Keep only last 10 searches
      if (current.length > 10) {
        current.removeRange(10, current.length);
      }

      await prefs.setStringList(_recentSearchesKey, current);
    } catch (e) {
      throw Exception('Save recent search failed: ${e.toString()}');
    }
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      return searches;
    } catch (e) {
      throw Exception('Get recent searches failed: ${e.toString()}');
    }
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      throw Exception('Clear recent searches failed: ${e.toString()}');
    }
  }

  /// Clear user session (logout)
  Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      throw Exception('Clear session failed: ${e.toString()}');
    }
  }

  /// Add to login history
  Future<void> _addLoginHistory(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? historyJson = prefs.getString(_loginHistoryKey);

      List<Map<String, dynamic>> history = [];

      if (historyJson != null) {
        List<dynamic> decodedHistory = jsonDecode(historyJson);
        history = decodedHistory.cast<Map<String, dynamic>>();
      }

      // Add login entry
      Map<String, dynamic> loginEntry = {
        'uid': user.uid,
        'email': user.email,
        'fullName': user.fullName,
        'loginTime': DateTime.now().toIso8601String(),
      };

      history.add(loginEntry);

      // Keep only last 50 logins
      if (history.length > 50) {
        history = history.sublist(history.length - 50);
      }

      String updatedHistoryJson = jsonEncode(history);
      await prefs.setString(_loginHistoryKey, updatedHistoryJson);
    } catch (e) {
      throw Exception('Add login history failed: ${e.toString()}');
    }
  }

  /// Get login history
  Future<List<Map<String, dynamic>>> getLoginHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? historyJson = prefs.getString(_loginHistoryKey);

      if (historyJson == null) {
        return [];
      }

      List<dynamic> decodedHistory = jsonDecode(historyJson);
      return decodedHistory.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Get login history failed: ${e.toString()}');
    }
  }

  /// Clear login history
  Future<void> clearLoginHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginHistoryKey);
    } catch (e) {
      throw Exception('Clear login history failed: ${e.toString()}');
    }
  }

  /// Check if user session exists
  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userKey);
    } catch (e) {
      return false;
    }
  }
}
