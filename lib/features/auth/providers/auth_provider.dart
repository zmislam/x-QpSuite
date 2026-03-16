import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/socket_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final SocketService _socket;

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  AuthProvider({required ApiService api, required SocketService socket})
      : _api = api,
        _socket = socket;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  /// Restore session from secure storage on app launch.
  Future<void> initAuth() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    _api.setToken(token);

    // Try to restore cached user first for instant UI
    final cachedUser = StorageService.getString(StorageKeys.userJson);
    if (cachedUser != null) {
      _user = UserModel.fromJson(jsonDecode(cachedUser));
      _isAuthenticated = true;
      notifyListeners();
    }

    // Verify token is still valid by fetching profile
    try {
      final res = await _api.get(ApiConstants.userProfile);
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']);
        _isAuthenticated = true;
        await StorageService.setString(
            StorageKeys.userJson, jsonEncode(_user!.toJson()));
        _socket.connect(token);
      } else {
        await _clearSession();
      }
    } catch (e) {
      // If offline but we have cached data, stay authenticated
      if (_user != null) {
        _isAuthenticated = true;
      } else {
        await _clearSession();
      }
    }
    notifyListeners();
  }

  /// Login with email/username and password.
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (res.data['success'] == true) {
        final token = res.data['token'] as String;
        _user = UserModel.fromJson(res.data['data']);
        _isAuthenticated = true;
        _api.setToken(token);
        await StorageService.setToken(token);
        await StorageService.setString(
            StorageKeys.userJson, jsonEncode(_user!.toJson()));
        _socket.connect(token);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res.data['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout — clear all session data.
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _user = null;
    _isAuthenticated = false;
    _api.setToken(null);
    _socket.disconnect();
    await StorageService.clearToken();
    await StorageService.remove(StorageKeys.userJson);
    await StorageService.remove(StorageKeys.lastSelectedPageId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
