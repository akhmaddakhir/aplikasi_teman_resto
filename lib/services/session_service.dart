import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  static const String _userKey = 'logged_in_user';
  static const String _loginHistoryKey = 'login_history';

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
