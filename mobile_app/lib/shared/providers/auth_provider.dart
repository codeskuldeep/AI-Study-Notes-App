import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/app_error.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isOnboarded;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.isOnboarded = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isOnboarded,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isOnboarded: isOnboarded ?? this.isOnboarded,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  final _api = ApiClient.instance;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    final isOnboarded = settingsBox.get(AppConstants.onboardingKey, defaultValue: false) as bool;
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);

    if (accessToken != null) {
      final userJson = settingsBox.get(AppConstants.userKey);
      UserModel? user;
      if (userJson != null) {
        user = UserModel.fromJson(jsonDecode(userJson as String));
      }
      state = AuthState(isLoggedIn: true, isOnboarded: isOnboarded, user: user);
      _refreshProfile();
    } else {
      state = AuthState(isLoggedIn: false, isOnboarded: isOnboarded);
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final response = await _api.get('/auth/profile/');
      final user = UserModel.fromJson(response.data['data']);
      _saveUser(user);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  void _saveUser(UserModel user) {
    Hive.box(AppConstants.settingsBox).put(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/login/', data: {'email': email, 'password': password});
      final data = response.data['data'];
      await _storage.write(key: AppConstants.accessTokenKey, value: data['access']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh']);
      final user = UserModel.fromJson(data['user']);
      _saveUser(user);
      state = state.copyWith(isLoggedIn: true, isLoading: false, user: user);
      return null;
    } on Exception catch (e) {
      final error = AppError.fromDioException(e as dynamic).message;
      state = state.copyWith(isLoading: false, error: error);
      return error;
    }
  }

  Future<String?> register(String email, String fullName, String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/register/', data: {
        'email': email,
        'full_name': fullName,
        'username': username,
        'password': password,
        'password_confirm': password,
      });
      final data = response.data['data'];
      await _storage.write(key: AppConstants.accessTokenKey, value: data['access']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh']);
      final user = UserModel.fromJson(data['user']);
      _saveUser(user);
      state = state.copyWith(isLoggedIn: true, isLoading: false, user: user);
      return null;
    } catch (e) {
      final msg = AppError.fromDioException(e as dynamic).message;
      state = state.copyWith(isLoading: false, error: msg);
      return msg;
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      await _api.post('/auth/logout/', data: {'refresh': refresh});
    } catch (_) {}
    await _storage.deleteAll();
    Hive.box(AppConstants.settingsBox).delete(AppConstants.userKey);
    state = AuthState(isOnboarded: state.isOnboarded);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    state = state.copyWith(user: updatedUser);
    _saveUser(updatedUser);
  }

  void completeOnboarding() {
    Hive.box(AppConstants.settingsBox).put(AppConstants.onboardingKey, true);
    state = state.copyWith(isOnboarded: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});
